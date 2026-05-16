module Api.Profile.Handler where

import Data.Text (Text)
import Database.Persist (deleteBy, insertBy)
import Database.Persist.Sql (Entity (..))
import Effectful.Error.Static (throwError)
import Servant (NamedRoutes)
import Servant qualified as S
import Servant.Auth.Server qualified as S

import Api.Profile.Type
import Common.Type.App (App)
import DB.Schema.Type (UserId)
import DB.Schema.Type qualified as DB
import DB.Util (runDB)
import Entity.Follow.Query (isFollowing)
import Entity.User.Api (Profile (..), ProfileResponse (..))
import Entity.User.Query (getUserByUsername)

profilesServer :: S.AuthResult UserId -> S.ServerT (NamedRoutes ProfilesRoutes) App
profilesServer auth =
  ProfilesRoutes
    { profile = \username ->
        ProfileRoutes
          { get = getProfileHandler auth username
          , follow = followHandler auth username
          , unfollow = unfollowHandler auth username
          }
    }

getProfileHandler :: S.AuthResult UserId -> Text -> App ProfileResponse
getProfileHandler auth username = do
  mUser <- runDB (getUserByUsername username)
  case mUser of
    Nothing -> throwError S.err404{S.errBody = "UserResponse not found"}
    Just (Entity uid u) -> do
      isFol <- case auth of
        S.Authenticated currentUid -> runDB (isFollowing currentUid uid)
        _ -> return False
      return $ ProfileResponse $ Profile u.username u.bio u.image isFol

followHandler :: S.AuthResult UserId -> Text -> App ProfileResponse
followHandler (S.Authenticated currentUid) username = do
  mUser <- runDB (getUserByUsername username)
  case mUser of
    Nothing -> throwError S.err404{S.errBody = "UserResponse not found"}
    Just (Entity uid u) -> do
      _ <- runDB (insertBy (DB.Follow currentUid uid))
      return $ ProfileResponse $ Profile u.username u.bio u.image True
followHandler _ _ = throwError S.err401

unfollowHandler :: S.AuthResult UserId -> Text -> App ProfileResponse
unfollowHandler (S.Authenticated currentUid) username = do
  mUser <- runDB (getUserByUsername username)
  case mUser of
    Nothing -> throwError S.err404{S.errBody = "UserResponse not found"}
    Just (Entity uid u) -> do
      runDB (deleteBy (DB.UniqueFollow currentUid uid))
      return $ ProfileResponse $ Profile u.username u.bio u.image False
unfollowHandler _ _ = throwError S.err401

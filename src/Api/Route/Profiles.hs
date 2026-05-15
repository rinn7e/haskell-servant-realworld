module Api.Route.Profiles where

import Data.Text (Text)
import Database.Persist (deleteBy, insertBy)
import Database.Persist.Sql (Entity (..), runSqlPool)
import Effectful (liftIO)
import Effectful.Error.Static (throwError)
import Effectful.Reader.Static (ask)
import GHC.Generics (Generic)
import Servant (Capture, Delete, GenericMode (type (:-)), Get, JSON, NamedRoutes, Post, (:>))
import Servant qualified as S
import Servant.Auth.Server qualified as S

import Api.Type (Profile (..))
import Common.Type.App (App, AppEnv (..))
import DB.Follow.Query (isFollowing)
import DB.User.Query (getUserByUsername)
import DB.Schema.Type (UserId)
import DB.Schema.Type qualified as DB
import DB.Util (runDB)

data ProfilesRoutes mode = ProfilesRoutes
  { profile :: mode :- Capture "username" Text :> NamedRoutes ProfileRoutes
  }
  deriving stock (Generic)

data ProfileRoutes mode = ProfileRoutes
  { get :: mode :- Get '[JSON] Profile
  -- ^ GET /api/profiles/:username
  , follow :: mode :- "follow" :> Post '[JSON] Profile
  -- ^ POST /api/profiles/:username/follow
  , unfollow :: mode :- "follow" :> Delete '[JSON] Profile
  -- ^ DELETE /api/profiles/:username/follow
  }
  deriving stock (Generic)

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

getProfileHandler :: S.AuthResult UserId -> Text -> App Profile
getProfileHandler auth username = do
  mUser <- runDB (getUserByUsername username)
  case mUser of
    Nothing -> throwError S.err404{S.errBody = "User not found"}
    Just (Entity uid u) -> do
      isFol <- case auth of
        S.Authenticated currentUid -> runDB (isFollowing currentUid uid)
        _ -> return False
      return $ Profile u.username u.bio u.image isFol

followHandler :: S.AuthResult UserId -> Text -> App Profile
followHandler (S.Authenticated currentUid) username = do
  mUser <- runDB (getUserByUsername username)
  case mUser of
    Nothing -> throwError S.err404{S.errBody = "User not found"}
    Just (Entity uid u) -> do
      _ <- runDB (insertBy (DB.Follow currentUid uid))
      return $ Profile u.username u.bio u.image True
followHandler _ _ = throwError S.err401

unfollowHandler :: S.AuthResult UserId -> Text -> App Profile
unfollowHandler (S.Authenticated currentUid) username = do
  mUser <- runDB (getUserByUsername username)
  case mUser of
    Nothing -> throwError S.err404{S.errBody = "User not found"}
    Just (Entity uid u) -> do
      runDB (deleteBy (DB.UniqueFollow currentUid uid))
      return $ Profile u.username u.bio u.image False
unfollowHandler _ _ = throwError S.err401

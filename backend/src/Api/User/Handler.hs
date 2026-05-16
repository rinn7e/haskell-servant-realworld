module Api.User.Handler where

import Data.Password.Argon2 (hashPassword, mkPassword, unPasswordHash)
import Data.Text (Text)
import Database.Persist (deleteBy, get, insertBy, replace)
import Database.Persist.Sql (Entity (..))
import Effectful (liftIO)
import Effectful.Error.Static (throwError)
import Effectful.Reader.Static (ask)
import Servant (NamedRoutes)
import Servant qualified as S
import Servant.Auth.Server qualified as S

import Api.User.Type
import Common.Type.App (App, AppEnv (..))
import Common.Type.JWK (generateToken)
import DB.Schema.Type (UserId)
import DB.Schema.Type qualified as DB
import DB.Util (runDB)
import Entity.Follow.Query (isFollowing)
import Entity.User.Api
  ( Profile (..)
  , ProfileResponse (..)
  , UpdateUserRequest (..)
  , User (..)
  , UserResponse (..)
  )
import Entity.User.Query (getUserByUsername)

userServer :: S.AuthResult UserId -> S.ServerT (NamedRoutes UserRoutes) App
userServer auth =
  UserRoutes
    { getCurrentUser = getCurrentUser auth
    , updateCurrentUser = updateCurrentUser auth
    , getUserByName = getUserByName auth
    , followUser = followUser auth
    , unfollowUser = unfollowUser auth
    }

getCurrentUser :: S.AuthResult UserId -> App UserResponse
getCurrentUser (S.Authenticated uid) = do
  AppEnv{appJwtKey = jwtKey} <- ask
  mUser <- runDB (get uid)
  case mUser of
    Nothing -> throwError S.err401
    Just u -> do
      token <- liftIO $ generateToken jwtKey uid
      return $ UserResponse $ User u.email token u.username u.bio u.image
getCurrentUser _ = throwError S.err401

updateCurrentUser
  :: S.AuthResult UserId -> UpdateUserRequest -> App UserResponse
updateCurrentUser (S.Authenticated uid) (UpdateUserRequest mEmail mUsername mPassword mBio mImage) = do
  AppEnv{appJwtKey = jwtKey} <- ask
  mUser <- runDB (get (uid :: UserId))
  case mUser of
    Nothing -> throwError S.err401
    Just u -> do
      newHashedPwd <- case mPassword of
        Just pwd -> liftIO $ unPasswordHash <$> hashPassword (mkPassword pwd)
        Nothing -> return u.password

      let newUser =
            DB.User
              { email = maybe u.email id mEmail
              , username = maybe u.username id mUsername
              , password = newHashedPwd
              , bio = maybe u.bio Just mBio
              , image = maybe u.image Just mImage
              }

      runDB (replace uid newUser)
      token <- liftIO $ generateToken jwtKey uid
      return $
        UserResponse $
          User newUser.email token newUser.username newUser.bio newUser.image
updateCurrentUser _ _ = throwError S.err401

getUserByName :: S.AuthResult UserId -> Text -> App ProfileResponse
getUserByName auth username = do
  mUser <- runDB (getUserByUsername username)
  case mUser of
    Nothing -> throwError S.err404{S.errBody = "UserResponse not found"}
    Just (Entity uid u) -> do
      isFol <- case auth of
        S.Authenticated currentUid -> runDB (isFollowing currentUid uid)
        _ -> return False
      return $ ProfileResponse $ Profile u.username u.bio u.image isFol

followUser :: S.AuthResult UserId -> Text -> App ProfileResponse
followUser (S.Authenticated currentUid) username = do
  mUser <- runDB (getUserByUsername username)
  case mUser of
    Nothing -> throwError S.err404{S.errBody = "UserResponse not found"}
    Just (Entity uid u) -> do
      _ <- runDB (insertBy (DB.Follow currentUid uid))
      return $ ProfileResponse $ Profile u.username u.bio u.image True
followUser _ _ = throwError S.err401

unfollowUser :: S.AuthResult UserId -> Text -> App ProfileResponse
unfollowUser (S.Authenticated currentUid) username = do
  mUser <- runDB (getUserByUsername username)
  case mUser of
    Nothing -> throwError S.err404{S.errBody = "UserResponse not found"}
    Just (Entity uid u) -> do
      runDB (deleteBy (DB.UniqueFollow currentUid uid))
      return $ ProfileResponse $ Profile u.username u.bio u.image False
unfollowUser _ _ = throwError S.err401

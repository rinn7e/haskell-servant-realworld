module Api.Route.User where

import Data.Password.Argon2 (hashPassword, mkPassword, unPasswordHash)
import Database.Persist (get, replace)
import Database.Persist.Sql (runSqlPool)
import Effectful (liftIO)
import Effectful.Error.Static (throwError)
import Effectful.Reader.Static (ask)
import GHC.Generics (Generic)
import Servant (GenericMode (type (:-)), Get, JSON, NamedRoutes, Put, ReqBody, (:>))
import Servant qualified as S
import Servant.Auth.Server qualified as S

import Api.Type (UpdateUserRequest (..), User (..), UserResponse (..))
import Common.Type.App (App, AppEnv (..))
import Common.Util.Auth (generateToken)
import DB.Schema.Type (UserId)
import DB.Schema.Type qualified as DB
import DB.Util (runDB)

data UserRoutes mode = UserRoutes
  { get :: mode :- Get '[JSON] UserResponse
  -- ^ GET /api/user
  , update :: mode :- ReqBody '[JSON] UpdateUserRequest :> Put '[JSON] UserResponse
  -- ^ PUT /api/user
  }
  deriving stock (Generic)

userServer :: S.AuthResult UserId -> S.ServerT (NamedRoutes UserRoutes) App
userServer auth =
  UserRoutes
    { get = getCurrentUserHandler auth
    , update = updateCurrentUserHandler auth
    }

getCurrentUserHandler :: S.AuthResult UserId -> App UserResponse
getCurrentUserHandler (S.Authenticated uid) = do
  AppEnv{appJwtKey = jwtKey} <- ask
  mUser <- runDB (get uid)
  case mUser of
    Nothing -> throwError S.err401
    Just u -> do
      token <- liftIO $ generateToken jwtKey uid
      return $ UserResponse $ User u.email token u.username u.bio u.image
getCurrentUserHandler _ = throwError S.err401

updateCurrentUserHandler :: S.AuthResult UserId -> UpdateUserRequest -> App UserResponse
updateCurrentUserHandler (S.Authenticated uid) (UpdateUserRequest mEmail mUsername mPassword mBio mImage) = do
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
      return $ UserResponse $ User newUser.email token newUser.username newUser.bio newUser.image
updateCurrentUserHandler _ _ = throwError S.err401

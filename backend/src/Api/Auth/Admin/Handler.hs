module Api.Auth.Admin.Handler where

import Data.Password.Argon2
  ( PasswordCheck (..)
  , PasswordHash (..)
  , checkPassword
  , mkPassword
  )
import Database.Persist (Entity (..))
import Effectful (liftIO)
import Effectful.Error.Static (throwError)
import Effectful.Reader.Static (ask)
import Servant (NamedRoutes)
import Servant qualified as S
import Servant.Auth.Server qualified as S

import Api.Auth.Admin.Type
import Common.Type.App (App, AppEnv (..))
import Common.Type.JWK (generateToken)
import DB.Schema.Type (UserId)
import DB.Schema.Type qualified as DB
import DB.Util (runDB)
import Entity.User.Api
  ( LoginUserRequest (..)
  , User (..)
  , UserResponse (..)
  )
import Entity.User.Query (getUserByEmail)

adminAuthRoute :: S.AuthResult UserId -> S.ServerT (NamedRoutes AdminAuthRoute) App
adminAuthRoute auth =
  AdminAuthRoute
    { loginAdmin = loginAdminHandler auth
    }

loginAdminHandler :: S.AuthResult UserId -> LoginUserRequest -> App UserResponse
loginAdminHandler _ (LoginUserRequest email pwd) = do
  AppEnv{appJwtKey = jwtKey} <- ask
  mUser <- runDB (getUserByEmail email)
  case mUser of
    Nothing -> throwError S.err401{S.errBody = "Invalid email or password"}
    Just (Entity uid u) -> do
      case checkPassword (mkPassword pwd) (PasswordHash u.password) of
        PasswordCheckFail -> throwError S.err401{S.errBody = "Invalid email or password"}
        PasswordCheckSuccess -> do
          if u.role /= "Admin"
            then throwError S.err403{S.errBody = "Access Denied: Administrator role required"}
            else do
              token <- liftIO $ generateToken jwtKey uid
              return $ UserResponse $ User u.email token u.username u.bio u.image

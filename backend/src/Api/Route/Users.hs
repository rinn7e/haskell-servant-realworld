module Api.Route.Users where

import Data.Password.Argon2 (PasswordCheck (..), PasswordHash (..), checkPassword, hashPassword, mkPassword, unPasswordHash)
import Database.Persist (Entity (..), insert)
import Database.Persist.Sql (SqlBackend, runSqlPool)
import Effectful (liftIO)
import Effectful.Error.Static (throwError)
import Effectful.Reader.Static (ask)
import GHC.Generics (Generic)
import Servant (GenericMode (type (:-)), JSON, NamedRoutes, Post, PostCreated, ReqBody, (:>))
import Servant qualified as S
import Servant.Auth.Server qualified as S

import Api.Type.User (LoginUserRequest (..), NewUserRequest (..), User (..), UserResponse (..))
import Common.Type.App (App, AppEnv (..))
import Common.Util.Auth (generateToken)
import DB.Schema.Type (UserId)
import DB.Schema.Type qualified as DB
import DB.User.Query (getUserByEmail)
import DB.Util (runDB)

data UsersRoutes mode = UsersRoutes
  { login :: mode :- "login" :> ReqBody '[JSON] LoginUserRequest :> Post '[JSON] UserResponse
  -- ^ POST /api/users/login
  , register :: mode :- ReqBody '[JSON] NewUserRequest :> PostCreated '[JSON] UserResponse
  -- ^ POST /api/users
  }
  deriving stock (Generic)

usersServer :: S.AuthResult UserId -> S.ServerT (NamedRoutes UsersRoutes) App
usersServer auth =
  UsersRoutes
    { login = loginHandler auth
    , register = registerHandler auth
    }

loginHandler :: S.AuthResult UserId -> LoginUserRequest -> App UserResponse
loginHandler _ (LoginUserRequest email pwd) = do
  AppEnv{appJwtKey = jwtKey} <- ask
  mUser <- runDB (getUserByEmail email)
  case mUser of
    Nothing -> throwError S.err401{S.errBody = "Invalid email or password"}
    Just (Entity uid u) -> do
      case checkPassword (mkPassword pwd) (PasswordHash u.password) of
        PasswordCheckSuccess -> do
          token <- liftIO $ generateToken jwtKey uid
          return $ UserResponse $ User u.email token u.username u.bio u.image
        PasswordCheckFail -> throwError S.err401{S.errBody = "Invalid email or password"}

registerHandler :: S.AuthResult UserId -> NewUserRequest -> App UserResponse
registerHandler _ (NewUserRequest username email pwd) = do
  AppEnv{appJwtKey = jwtKey} <- ask
  hashedPwd <- liftIO $ hashPassword (mkPassword pwd)
  uid <- runDB $ insert $ DB.User username email (unPasswordHash hashedPwd) Nothing Nothing
  token <- liftIO $ generateToken jwtKey uid
  return $ UserResponse $ User email token username Nothing Nothing

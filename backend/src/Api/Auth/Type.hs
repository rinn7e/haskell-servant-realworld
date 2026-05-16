module Api.Auth.Type where

import GHC.Generics (Generic)
import Servant (GenericMode (type (:-)), JSON, Post, PostCreated, ReqBody, (:>))

import Entity.User.Api (LoginUserRequest, NewUserRequest, UserResponse)

data AuthRoutes mode = AuthRoutes
  { login
      :: mode
        :- "users" :> "login" :> ReqBody '[JSON] LoginUserRequest :> Post '[JSON] UserResponse
  -- ^ POST /api/users/login
  , register
      :: mode :- "users" :> ReqBody '[JSON] NewUserRequest :> PostCreated '[JSON] UserResponse
  -- ^ POST /api/users
  }
  deriving stock (Generic)

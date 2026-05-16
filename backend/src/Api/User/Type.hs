module Api.User.Type where

import GHC.Generics (Generic)
import Servant (GenericMode (type (:-)), Get, JSON, Put, ReqBody, (:>))

import Entity.User.Api (UpdateUserRequest, UserResponse)

data UserRoutes mode = UserRoutes
  { get :: mode :- "user" :> Get '[JSON] UserResponse
  -- ^ GET /api/user
  , update :: mode :- "user" :> ReqBody '[JSON] UpdateUserRequest :> Put '[JSON] UserResponse
  -- ^ PUT /api/user
  }
  deriving stock (Generic)

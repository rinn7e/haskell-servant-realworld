module Api.Auth.Type where

import GHC.Generics (Generic)
import Servant
  ( Description
  , GenericMode (type (:-))
  , JSON
  , Post
  , PostCreated
  , ReqBody
  , Summary
  , (:>)
  )

import Entity.User.Api (LoginUserRequest, NewUserRequest, UserResponse)

data AuthRoute mode = AuthRoute
  { loginUser
      :: mode
        :- "users"
          :> "login"
          :> Summary "Login"
          :> Description "Login an existing user"
          :> ReqBody '[JSON] LoginUserRequest
          :> Post '[JSON] UserResponse
  -- ^ POST /api/users/login
  , registerUser
      :: mode
        :- "users"
          :> Summary "Register"
          :> Description "Register a new user"
          :> ReqBody '[JSON] NewUserRequest
          :> PostCreated '[JSON] UserResponse
  -- ^ POST /api/users
  }
  deriving stock (Generic)

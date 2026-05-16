module Api.User.Type where

import Data.Text (Text)
import GHC.Generics (Generic)
import Servant
  ( Capture
  , Delete
  , GenericMode (type (:-))
  , Get
  , JSON
  , Post
  , Put
  , ReqBody
  , (:>)
  )

import Entity.User.Api (ProfileResponse, UpdateUserRequest, UserResponse)

data UserRoute mode = UserRoute
  { getCurrentUser :: mode :- "user" :> Get '[JSON] UserResponse
  -- ^ GET /api/user
  , updateCurrentUser :: mode :- "user" :> ReqBody '[JSON] UpdateUserRequest :> Put '[JSON] UserResponse
  -- ^ PUT /api/user
  , getUserByName :: mode :- "profiles" :> Capture "username" Text :> Get '[JSON] ProfileResponse
  -- ^ GET /api/profiles/:username
  , followUser :: mode :- "profiles" :> Capture "username" Text :> "follow" :> Post '[JSON] ProfileResponse
  -- ^ POST /api/profiles/:username/follow
  , unfollowUser :: mode :- "profiles" :> Capture "username" Text :> "follow" :> Delete '[JSON] ProfileResponse
  -- ^ DELETE /api/profiles/:username/follow
  }
  deriving stock (Generic)

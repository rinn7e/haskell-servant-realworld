module Api.Profile.Type where

import Data.Text (Text)
import GHC.Generics (Generic)
import Servant
  ( Capture
  , Delete
  , GenericMode (type (:-))
  , Get
  , JSON
  , NamedRoutes
  , Post
  , (:>)
  )

import Entity.User.Api (ProfileResponse)

data ProfilesRoutes mode = ProfilesRoutes
  { profile :: mode :- "profiles" :> Capture "username" Text :> NamedRoutes ProfileRoutes
  }
  deriving stock (Generic)

data ProfileRoutes mode = ProfileRoutes
  { get :: mode :- Get '[JSON] ProfileResponse
  -- ^ GET /api/profiles/:username
  , follow :: mode :- "follow" :> Post '[JSON] ProfileResponse
  -- ^ POST /api/profiles/:username/follow
  , unfollow :: mode :- "follow" :> Delete '[JSON] ProfileResponse
  -- ^ DELETE /api/profiles/:username/follow
  }
  deriving stock (Generic)

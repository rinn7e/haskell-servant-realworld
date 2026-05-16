module Api.Tag.Type where

import GHC.Generics (Generic)
import Servant (GenericMode (type (:-)), Get, JSON, (:>))

import Entity.Tag.Api (TagListResponse)

data TagRoute mode = TagRoute
  { getTagList :: mode :- "tags" :> Get '[JSON] TagListResponse
  -- ^ GET /api/tags
  }
  deriving stock (Generic)

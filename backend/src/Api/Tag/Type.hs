module Api.Tag.Type where

import GHC.Generics (Generic)
import Servant
  ( Description
  , GenericMode (type (:-))
  , Get
  , JSON
  , Summary
  , (:>)
  )

import Entity.Tag.Api (TagListResponse)

data TagRoute mode = TagRoute
  { getTagList
      :: mode
        :- "tags"
          :> Summary "Get Tags"
          :> Description "Get a list of all tags"
          :> Get '[JSON] TagListResponse
  -- ^ GET /api/tags
  }
  deriving stock (Generic)

module Api.Metadata.Type where

import GHC.Generics (Generic)
import Servant
  ( Description
  , GenericMode (type (:-))
  , Get
  , JSON
  , Summary
  , (:>)
  )

import Common.Type.Metadata (MetadataResponse)

data MetadataRoute mode = MetadataRoute
  { getMetadata
      :: mode
        :- "metadata"
          :> Summary "Get Metadata"
          :> Description "Get backend system metadata"
          :> Get '[JSON] MetadataResponse
  -- ^ GET /api/metadata
  }
  deriving stock (Generic)

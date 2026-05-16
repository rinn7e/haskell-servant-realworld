module Api.Metadata.Type where

import GHC.Generics (Generic)
import Servant (GenericMode (type (:-)), Get, JSON, (:>))

import Common.Type.Metadata (MetadataResponse)

data MetadataRoute mode = MetadataRoute
  { getMetadata :: mode :- "metadata" :> Get '[JSON] MetadataResponse
  -- ^ GET /api/metadata
  }
  deriving stock (Generic)

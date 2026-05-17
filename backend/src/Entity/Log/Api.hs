module Entity.Log.Api where

import Data.Aeson (ToJSON (..))
import Data.Aeson qualified as A
import Data.OpenApi (ToSchema (..))
import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics (Generic)

data LogResponse = LogResponse
  { id :: Int
  , level :: Text
  , message :: Text
  , source :: Text
  , timestamp :: UTCTime
  , userId :: Maybe Int
  }
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, ToSchema)

data LogListResponse = LogListResponse
  { logs :: [LogResponse]
  , totalCount :: Int
  }
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, ToSchema)

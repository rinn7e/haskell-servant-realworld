module Common.Type.Metadata where

import Data.Aeson (ToJSON (..))
import Data.Aeson qualified as A
import Data.Text (Text)
import GHC.Generics (Generic)

-------------------------------
-- MetadataResponse
-------------------------------
data MetadataResponse = MetadataResponse
  { appVersion :: Text
  , lastCommitHash :: Text
  , lastRanMigration :: Maybe Int
  }
  deriving (Show, Generic)

instance ToJSON MetadataResponse where
  toJSON = A.genericToJSON A.defaultOptions

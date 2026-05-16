module Entity.Tag.Api where

import Data.Aeson (ToJSON (..), (.=))
import Data.Aeson qualified as A
import Data.Text (Text)
import GHC.Generics (Generic)

-------------------------------
-- TagListResponse
-------------------------------
data TagListResponse = TagListResponse
  { tags :: [Text]
  }
  deriving (Show, Generic)

instance ToJSON TagListResponse where
  toJSON (TagListResponse ts) = A.object ["tags" .= ts]

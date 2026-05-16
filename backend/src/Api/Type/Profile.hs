module Api.Type.Profile where

import Data.Aeson (ToJSON (..))
import Data.Aeson qualified as A
import Data.Text (Text)
import GHC.Generics (Generic)

-------------------------------
-- Profile
-------------------------------
data Profile = Profile
  { username :: Text
  , bio :: Maybe Text
  , image :: Maybe Text
  , following :: Bool
  }
  deriving (Show, Generic)

instance ToJSON Profile where
  toJSON = A.genericToJSON A.defaultOptions

-------------------------------
-- ProfileResponse
-------------------------------
data ProfileResponse = ProfileResponse {profile :: Profile} deriving (Show, Generic, ToJSON)

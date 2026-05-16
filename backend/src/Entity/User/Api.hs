module Entity.User.Api where

import Data.Aeson (FromJSON (..), ToJSON (..), (.:), (.:?))
import Data.Aeson qualified as A
import Data.Text (Text)
import GHC.Generics (Generic)

-------------------------------
-- User
-------------------------------
data User = User
  { email :: Text
  , token :: Text
  , username :: Text
  , bio :: Maybe Text
  , image :: Maybe Text
  }
  deriving (Show, Generic)

instance ToJSON User where
  toJSON = A.genericToJSON A.defaultOptions

-------------------------------
-- UserResponse
-------------------------------
data UserResponse = UserResponse {user :: User} deriving (Show, Generic, ToJSON)

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
data ProfileResponse = ProfileResponse {profile :: Profile}
  deriving (Show, Generic, ToJSON)

-------------------------------
-- LoginUserRequest
-------------------------------
data LoginUserRequest = LoginUserRequest
  { email :: Text
  , password :: Text
  }
  deriving (Show, Generic)

instance FromJSON LoginUserRequest where
  parseJSON = A.withObject "LoginUserRequest" $ \o -> do
    u <- o .: "user"
    LoginUserRequest <$> u .: "email" <*> u .: "password"

-------------------------------
-- NewUserRequest
-------------------------------
data NewUserRequest = NewUserRequest
  { username :: Text
  , email :: Text
  , password :: Text
  }
  deriving (Show, Generic)

instance FromJSON NewUserRequest where
  parseJSON = A.withObject "NewUserRequest" $ \o -> do
    u <- o .: "user"
    NewUserRequest <$> u .: "username" <*> u .: "email" <*> u .: "password"

-------------------------------
-- UpdateUserRequest
-------------------------------
data UpdateUserRequest = UpdateUserRequest
  { email :: Maybe Text
  , username :: Maybe Text
  , password :: Maybe Text
  , bio :: Maybe Text
  , image :: Maybe Text
  }
  deriving (Show, Generic)

instance FromJSON UpdateUserRequest where
  parseJSON = A.withObject "UpdateUserRequest" $ \o -> do
    u <- o .: "user"
    UpdateUserRequest
      <$> u .:? "email"
      <*> u .:? "username"
      <*> u .:? "password"
      <*> u .:? "bio"
      <*> u .:? "image"

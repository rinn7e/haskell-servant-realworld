module Api.Type.Comment where

import Data.Aeson (FromJSON (..), ToJSON (..), (.:), (.=))
import Data.Aeson qualified as A
import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics (Generic)

import Api.Type.Profile (Profile)

-------------------------------
-- Comment
-------------------------------
data Comment = Comment
  { id :: Int
  , createdAt :: UTCTime
  , updatedAt :: UTCTime
  , body :: Text
  , author :: Profile
  }
  deriving (Show, Generic)

instance ToJSON Comment where
  toJSON = A.genericToJSON A.defaultOptions

-------------------------------
-- CommentResponse
-------------------------------
data CommentResponse = CommentResponse {comment :: Comment} deriving (Show, Generic, ToJSON)

-------------------------------
-- CommentListResponse
-------------------------------
data CommentListResponse = CommentListResponse
  { comments :: [Comment]
  }
  deriving (Show, Generic)

instance ToJSON CommentListResponse where
  toJSON (CommentListResponse cs) = A.object ["comments" .= cs]

-------------------------------
-- NewCommentRequest
-------------------------------
data NewCommentRequest = NewCommentRequest
  { body :: Text
  }
  deriving (Show, Generic)

instance FromJSON NewCommentRequest where
  parseJSON = A.withObject "NewCommentRequest" $ \o -> do
    c <- o .: "comment"
    NewCommentRequest <$> c .: "body"

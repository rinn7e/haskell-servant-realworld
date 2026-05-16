module Entity.Comment.Api
  ( Comment (..)
  , CommentResponse (..)
  , CommentListResponse (..)
  , NewCommentRequest (..)
  , toCommentResponse
  )
where

import Data.Aeson (FromJSON (..), ToJSON (..), (.:), (.=))
import Data.Aeson qualified as A
import Data.Text (Text)
import Data.Time (UTCTime)
import Database.Persist.Sql (Entity (..), SqlPersistT, fromSqlKey)
import GHC.Generics (Generic)

import Common.Type.App (AppEnv)
import DB.Schema.Type (UserId)
import DB.Schema.Type qualified as DB
import Entity.Follow.Query (isFollowing)
import Entity.User.Api (Profile (..))

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
data CommentResponse = CommentResponse {comment :: Comment}
  deriving (Show, Generic, ToJSON)

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

-------------------------------
-- Helpers
-------------------------------

toCommentResponse
  :: AppEnv -> Maybe UserId -> (Entity DB.Comment, Entity DB.User) -> SqlPersistT IO Comment
toCommentResponse _ mCurrentUserId (Entity cid comm, Entity _ author) = do
  isFol <- case mCurrentUserId of
    Just uid -> isFollowing uid comm.authorId
    Nothing -> return False

  let profile = Profile author.username author.bio author.image isFol
  return $
    Comment (fromIntegral (fromSqlKey cid)) comm.createdAt comm.updatedAt comm.body profile

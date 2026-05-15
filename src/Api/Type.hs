module Api.Type where

import Data.Aeson (FromJSON, ToJSON, (.:), (.:?), (.=))
import Data.Aeson qualified as A
import Data.Text (Text)
import Data.Time (UTCTime)
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
data UserResponse = UserResponse { user :: User } deriving (Show, Generic, ToJSON)

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
data ProfileResponse = ProfileResponse { profile :: Profile } deriving (Show, Generic, ToJSON)

-------------------------------
-- Article
-------------------------------
data Article = Article
  { slug :: Text
  , title :: Text
  , description :: Text
  , body :: Text
  , tagList :: [Text]
  , createdAt :: UTCTime
  , updatedAt :: UTCTime
  , favorited :: Bool
  , favoritesCount :: Int
  , author :: Profile
  }
  deriving (Show, Generic)

instance ToJSON Article where
  toJSON = A.genericToJSON A.defaultOptions

-------------------------------
-- ArticleResponse
-------------------------------
data ArticleResponse = ArticleResponse { article :: Article } deriving (Show, Generic, ToJSON)

-------------------------------
-- ArticleListResponse
-------------------------------
data ArticleListResponse = ArticleListResponse
  { articles :: [Article]
  , articlesCount :: Int
  }
  deriving (Show, Generic)

instance ToJSON ArticleListResponse where
  toJSON (ArticleListResponse as c) =
    A.object
      [ "articles" .= as
      , "articlesCount" .= c
      ]

-------------------------------
-- NewArticleRequest
-------------------------------
data NewArticleRequest = NewArticleRequest
  { title :: Text
  , description :: Text
  , body :: Text
  , tagList :: Maybe [Text]
  }
  deriving (Show, Generic)

instance FromJSON NewArticleRequest where
  parseJSON = A.withObject "NewArticleRequest" $ \o -> do
    a <- o .: "article"
    NewArticleRequest
      <$> a .: "title"
      <*> a .: "description"
      <*> a .: "body"
      <*> a .:? "tagList"

-------------------------------
-- UpdateArticleRequest
-------------------------------
data UpdateArticleRequest = UpdateArticleRequest
  { title :: Maybe Text
  , description :: Maybe Text
  , body :: Maybe Text
  }
  deriving (Show, Generic)

instance FromJSON UpdateArticleRequest where
  parseJSON = A.withObject "UpdateArticleRequest" $ \o -> do
    a <- o .: "article"
    UpdateArticleRequest
      <$> a .:? "title"
      <*> a .:? "description"
      <*> a .:? "body"

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
data CommentResponse = CommentResponse { comment :: Comment } deriving (Show, Generic, ToJSON)

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
-- TagListResponse
-------------------------------
data TagListResponse = TagListResponse
  { tags :: [Text]
  }
  deriving (Show, Generic)

instance ToJSON TagListResponse where
  toJSON (TagListResponse ts) = A.object ["tags" .= ts]

-------------------------------
-- GenericErrorResponse
-------------------------------
data GenericErrorResponse = GenericErrorResponse
  { errors :: A.Object
  }
  deriving (Show, Generic)

instance ToJSON GenericErrorResponse where
  toJSON (GenericErrorResponse errs) = A.object ["errors" .= errs]

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


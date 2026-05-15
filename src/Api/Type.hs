module Api.Type where

import Data.Aeson (FromJSON, ToJSON, (.:), (.:?), (.=))
import Data.Aeson qualified as A
import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics (Generic)

-- UserResponse
data UserResponse = UserResponse
  { email :: Text
  , token :: Text
  , username :: Text
  , bio :: Maybe Text
  , image :: Maybe Text
  }
  deriving (Show, Generic)

instance ToJSON UserResponse where
  toJSON u =
    A.object
      [ "user"
          .= A.object
            [ "email" .= u.email
            , "token" .= u.token
            , "username" .= u.username
            , "bio" .= u.bio
            , "image" .= u.image
            ]
      ]

data LoginUserRequest = LoginUserRequest
  { email :: Text
  , password :: Text
  }
  deriving (Show, Generic)

instance FromJSON LoginUserRequest where
  parseJSON = A.withObject "LoginUserRequest" $ \o -> do
    u <- o .: "user"
    LoginUserRequest <$> u .: "email" <*> u .: "password"

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

-- ProfileResponse
data ProfileResponse = ProfileResponse
  { username :: Text
  , bio :: Maybe Text
  , image :: Maybe Text
  , following :: Bool
  }
  deriving (Show, Generic)

instance ToJSON ProfileResponse where
  toJSON p =
    A.object
      [ "profile"
          .= A.object
            [ "username" .= p.username
            , "bio" .= p.bio
            , "image" .= p.image
            , "following" .= p.following
            ]
      ]

-- ArticleResponse
data ArticleResponse = ArticleResponse
  { slug :: Text
  , title :: Text
  , description :: Text
  , body :: Text
  , tagList :: [Text]
  , createdAt :: UTCTime
  , updatedAt :: UTCTime
  , favorited :: Bool
  , favoritesCount :: Int
  , author :: ProfileResponse
  }
  deriving (Show, Generic)

instance ToJSON ArticleResponse where
  toJSON a = A.object ["article" .= a]

-- Multiple Articles
data ArticleListResponse = ArticleListResponse
  { articles :: [ArticleResponse]
  , articlesCount :: Int
  }
  deriving (Show, Generic)

instance ToJSON ArticleListResponse where
  toJSON (ArticleListResponse as c) =
    A.object
      [ "articles" .= as
      , "articlesCount" .= c
      ]

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

-- CommentResponse
data CommentResponse = CommentResponse
  { id :: Int
  , createdAt :: UTCTime
  , updatedAt :: UTCTime
  , body :: Text
  , author :: ProfileResponse
  }
  deriving (Show, Generic)

instance ToJSON CommentResponse where
  toJSON c = A.object ["comment" .= c]

data CommentListResponse = CommentListResponse
  { comments :: [CommentResponse]
  }
  deriving (Show, Generic)

instance ToJSON CommentListResponse where
  toJSON (CommentListResponse cs) = A.object ["comments" .= cs]

data NewCommentRequest = NewCommentRequest
  { body :: Text
  }
  deriving (Show, Generic)

instance FromJSON NewCommentRequest where
  parseJSON = A.withObject "NewCommentRequest" $ \o -> do
    c <- o .: "comment"
    NewCommentRequest <$> c .: "body"

-- Tags
data TagListResponse = TagListResponse
  { tags :: [Text]
  }
  deriving (Show, Generic)

instance ToJSON TagListResponse where
  toJSON (TagListResponse ts) = A.object ["tags" .= ts]

-- Errors
data GenericErrorResponse = GenericErrorResponse
  { errors :: A.Object
  }
  deriving (Show, Generic)

instance ToJSON GenericErrorResponse where
  toJSON (GenericErrorResponse errs) = A.object ["errors" .= errs]

-- MetadataResponse
data MetadataResponse = MetadataResponse
  { appVersion :: Text
  , lastCommitHash :: Text
  , lastRanMigration :: Maybe Int
  }
  deriving (Show, Generic)

instance ToJSON MetadataResponse where
  toJSON m =
    A.object
      [ "app_version" .= m.appVersion
      , "last_commit_hash" .= m.lastCommitHash
      , "last_ran_migration" .= m.lastRanMigration
      ]

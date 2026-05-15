module Api.Type where

import Data.Aeson (FromJSON, ToJSON, (.:), (.:?), (.=))
import Data.Aeson qualified as A
import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics (Generic)

-- User
data User = User
  { email :: Text
  , token :: Text
  , username :: Text
  , bio :: Maybe Text
  , image :: Maybe Text
  }
  deriving (Show, Generic)

instance ToJSON User where
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

-- Profile
data Profile = Profile
  { username :: Text
  , bio :: Maybe Text
  , image :: Maybe Text
  , following :: Bool
  }
  deriving (Show, Generic)

instance ToJSON Profile where
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

-- Article
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
  toJSON a = A.object ["article" .= a]

-- Multiple Articles
data ArticlesResponse = ArticlesResponse
  { articles :: [Article]
  , articlesCount :: Int
  }
  deriving (Show, Generic)

instance ToJSON ArticlesResponse where
  toJSON (ArticlesResponse as c) =
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

-- Comment
data Comment = Comment
  { id :: Int
  , createdAt :: UTCTime
  , updatedAt :: UTCTime
  , body :: Text
  , author :: Profile
  }
  deriving (Show, Generic)

instance ToJSON Comment where
  toJSON c = A.object ["comment" .= c]

data CommentsResponse = CommentsResponse
  { comments :: [Comment]
  }
  deriving (Show, Generic)

instance ToJSON CommentsResponse where
  toJSON (CommentsResponse cs) = A.object ["comments" .= cs]

data NewCommentRequest = NewCommentRequest
  { body :: Text
  }
  deriving (Show, Generic)

instance FromJSON NewCommentRequest where
  parseJSON = A.withObject "NewCommentRequest" $ \o -> do
    c <- o .: "comment"
    NewCommentRequest <$> c .: "body"

-- Tags
data TagsResponse = TagsResponse
  { tags :: [Text]
  }
  deriving (Show, Generic)

instance ToJSON TagsResponse where
  toJSON (TagsResponse ts) = A.object ["tags" .= ts]

-- Errors
data GenericError = GenericError
  { errors :: A.Object
  }
  deriving (Show, Generic)

instance ToJSON GenericError where
  toJSON (GenericError errs) = A.object ["errors" .= errs]

-- Metadata
data Metadata = Metadata
  { appVersion :: Text
  , lastCommitHash :: Text
  , lastRanMigration :: Maybe Int
  }
  deriving (Show, Generic)

instance ToJSON Metadata where
  toJSON m =
    A.object
      [ "app_version" .= m.appVersion
      , "last_commit_hash" .= m.lastCommitHash
      , "last_ran_migration" .= m.lastRanMigration
      ]

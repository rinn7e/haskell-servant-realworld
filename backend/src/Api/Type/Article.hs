module Api.Type.Article where

import Data.Aeson (FromJSON (..), ToJSON (..), (.:), (.:?), (.=))
import Data.Aeson qualified as A
import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics (Generic)

import Api.Type.Profile (Profile)

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
data ArticleResponse = ArticleResponse {article :: Article} deriving (Show, Generic, ToJSON)

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
  , tagList :: Maybe [Text]
  }
  deriving (Show, Generic)

instance FromJSON UpdateArticleRequest where
  parseJSON = A.withObject "UpdateArticleRequest" $ \o -> do
    a <- o .: "article"
    UpdateArticleRequest
      <$> a .:? "title"
      <*> a .:? "description"
      <*> a .:? "body"
      <*> a .:? "tagList"

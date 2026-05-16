module Api.Article.Type where

import Data.Text (Text)
import GHC.Generics (Generic)
import Servant
  ( Capture
  , Delete
  , GenericMode (type (:-))
  , Get
  , JSON
  , NamedRoutes
  , Post
  , PostCreated
  , Put
  , QueryParam
  , ReqBody
  , (:>)
  )
import Servant qualified as S

import Entity.Article.Api
  ( ArticleListResponse
  , ArticleResponse
  , NewArticleRequest
  , UpdateArticleRequest
  )
import Entity.Comment.Api (CommentListResponse, CommentResponse, NewCommentRequest)

data ArticlesRoutes mode = ArticlesRoutes
  { feed
      :: mode
        :- "articles"
          :> "feed"
          :> QueryParam "limit" Int
          :> QueryParam "offset" Int
          :> Get '[JSON] ArticleListResponse
  -- ^ GET /api/articles/feed
  , list
      :: mode
        :- "articles"
          :> QueryParam "tag" Text
          :> QueryParam "author" Text
          :> QueryParam "favorited" Text
          :> QueryParam "limit" Int
          :> QueryParam "offset" Int
          :> Get '[JSON] ArticleListResponse
  -- ^ GET /api/articles
  , create
      :: mode
        :- "articles" :> ReqBody '[JSON] NewArticleRequest :> PostCreated '[JSON] ArticleResponse
  -- ^ POST /api/articles
  , article :: mode :- "articles" :> Capture "slug" Text :> NamedRoutes ArticleRoutes
  }
  deriving stock (Generic)

data ArticleRoutes mode = ArticleRoutes
  { get :: mode :- Get '[JSON] ArticleResponse
  -- ^ GET /api/articles/:slug
  , update :: mode :- ReqBody '[JSON] UpdateArticleRequest :> Put '[JSON] ArticleResponse
  -- ^ PUT /api/articles/:slug
  , delete :: mode :- Delete '[JSON] S.NoContent
  -- ^ DELETE /api/articles/:slug
  , comments :: mode :- "comments" :> NamedRoutes CommentsRoutes
  , favorite :: mode :- "favorite" :> Post '[JSON] ArticleResponse
  -- ^ POST /api/articles/:slug/favorite
  , unfavorite :: mode :- "favorite" :> Delete '[JSON] ArticleResponse
  -- ^ DELETE /api/articles/:slug/favorite
  }
  deriving stock (Generic)

data CommentsRoutes mode = CommentsRoutes
  { list :: mode :- Get '[JSON] CommentListResponse
  -- ^ GET /api/articles/:slug/comments
  , create :: mode :- ReqBody '[JSON] NewCommentRequest :> PostCreated '[JSON] CommentResponse
  -- ^ POST /api/articles/:slug/comments
  , delete :: mode :- Capture "id" Int :> Delete '[JSON] S.NoContent
  -- ^ DELETE /api/articles/:slug/comments/:id
  }
  deriving stock (Generic)

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

data ArticleRoute mode = ArticleRoute
  { getArticleFeed
      :: mode
        :- "articles"
          :> "feed"
          :> QueryParam "limit" Int
          :> QueryParam "offset" Int
          :> Get '[JSON] ArticleListResponse
  -- ^ GET /api/articles/feed
  , getArticleList
      :: mode
        :- "articles"
          :> QueryParam "tag" Text
          :> QueryParam "author" Text
          :> QueryParam "favorited" Text
          :> QueryParam "limit" Int
          :> QueryParam "offset" Int
          :> Get '[JSON] ArticleListResponse
  -- ^ GET /api/articles
  , createArticle
      :: mode
        :- "articles" :> ReqBody '[JSON] NewArticleRequest :> PostCreated '[JSON] ArticleResponse
  -- ^ POST /api/articles
  , getArticleOne
      :: mode
        :- "articles" :> Capture "slug" Text :> Get '[JSON] ArticleResponse
  -- ^ GET /api/articles/:slug
  , updateArticle
      :: mode
        :- "articles" :> Capture "slug" Text :> ReqBody '[JSON] UpdateArticleRequest :> Put '[JSON] ArticleResponse
  -- ^ PUT /api/articles/:slug
  , deleteArticle
      :: mode
        :- "articles" :> Capture "slug" Text :> Delete '[JSON] S.NoContent
  -- ^ DELETE /api/articles/:slug
  , favoriteArticle
      :: mode
        :- "articles" :> Capture "slug" Text :> "favorite" :> Post '[JSON] ArticleResponse
  -- ^ POST /api/articles/:slug/favorite
  , unfavoriteArticle
      :: mode
        :- "articles" :> Capture "slug" Text :> "favorite" :> Delete '[JSON] ArticleResponse
  -- ^ DELETE /api/articles/:slug/favorite
  , comments :: mode :- "articles" :> Capture "slug" Text :> "comments" :> NamedRoutes CommentRoute
  -- ^ /api/articles/:slug/comments
  }
  deriving stock (Generic)

data CommentRoute mode = CommentRoute
  { getCommentList :: mode :- Get '[JSON] CommentListResponse
  -- ^ GET /api/articles/:slug/comments
  , createComment :: mode :- ReqBody '[JSON] NewCommentRequest :> PostCreated '[JSON] CommentResponse
  -- ^ POST /api/articles/:slug/comments
  , deleteComment :: mode :- Capture "id" Int :> Delete '[JSON] S.NoContent
  -- ^ DELETE /api/articles/:slug/comments/:id
  }
  deriving stock (Generic)

module Api.Article.Type where

import Data.Text (Text)
import GHC.Generics (Generic)
import Servant
  ( Capture
  , Delete
  , Description
  , GenericMode (type (:-))
  , Get
  , JSON
  , NamedRoutes
  , Post
  , PostCreated
  , Put
  , QueryParam
  , ReqBody
  , Summary
  , (:>)
  )
import Servant qualified as S

import Api.TagCombinator (Tag)

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
          :> Summary "Get Feed"
          :> Description "Get a feed of recent articles from followed users"
          :> Tag "Articles"
          :> QueryParam "limit" Int
          :> QueryParam "offset" Int
          :> Get '[JSON] ArticleListResponse
  -- ^ GET /api/articles/feed
  , getArticleList
      :: mode
        :- "articles"
          :> Summary "Get Articles"
          :> Description "Get a list of recent articles"
          :> Tag "Articles"
          :> QueryParam "tag" Text
          :> QueryParam "author" Text
          :> QueryParam "favorited" Text
          :> QueryParam "limit" Int
          :> QueryParam "offset" Int
          :> Get '[JSON] ArticleListResponse
  -- ^ GET /api/articles
  , createArticle
      :: mode
        :- "articles"
          :> Summary "Create Article"
          :> Description "Create a new article"
          :> Tag "Articles"
          :> ReqBody '[JSON] NewArticleRequest
          :> PostCreated '[JSON] ArticleResponse
  -- ^ POST /api/articles
  , getArticleOne
      :: mode
        :- "articles"
          :> Capture "slug" Text
          :> Summary "Get Article"
          :> Description "Get a single article by slug"
          :> Tag "Articles"
          :> Get '[JSON] ArticleResponse
  -- ^ GET /api/articles/:slug
  , updateArticle
      :: mode
        :- "articles"
          :> Capture "slug" Text
          :> Summary "Update Article"
          :> Description "Update an article by slug"
          :> Tag "Articles"
          :> ReqBody '[JSON] UpdateArticleRequest
          :> Put '[JSON] ArticleResponse
  -- ^ PUT /api/articles/:slug
  , deleteArticle
      :: mode
        :- "articles"
          :> Capture "slug" Text
          :> Summary "Delete Article"
          :> Description "Delete an article by slug"
          :> Tag "Articles"
          :> Delete '[JSON] S.NoContent
  -- ^ DELETE /api/articles/:slug
  , favoriteArticle
      :: mode
        :- "articles"
          :> Capture "slug" Text
          :> "favorite"
          :> Summary "Favorite Article"
          :> Description "Favorite an article by slug"
          :> Tag "Articles"
          :> Post '[JSON] ArticleResponse
  -- ^ POST /api/articles/:slug/favorite
  , unfavoriteArticle
      :: mode
        :- "articles"
          :> Capture "slug" Text
          :> "favorite"
          :> Summary "Unfavorite Article"
          :> Description "Unfavorite an article by slug"
          :> Tag "Articles"
          :> Delete '[JSON] ArticleResponse
  -- ^ DELETE /api/articles/:slug/favorite
  , comments
      :: mode :- "articles" :> Capture "slug" Text :> "comments" :> NamedRoutes CommentRoute
  -- ^ /api/articles/:slug/comments
  }
  deriving stock (Generic)

data CommentRoute mode = CommentRoute
  { getCommentList
      :: mode
        :- Summary "Get Comments"
          :> Description "Get comments for an article"
          :> Tag "Articles"
          :> Get '[JSON] CommentListResponse
  -- ^ GET /api/articles/:slug/comments
  , createComment
      :: mode
        :- Summary "Create Comment"
          :> Description "Create a comment for an article"
          :> Tag "Articles"
          :> ReqBody '[JSON] NewCommentRequest
          :> PostCreated '[JSON] CommentResponse
  -- ^ POST /api/articles/:slug/comments
  , deleteComment
      :: mode
        :- Capture "id" Int
          :> Summary "Delete Comment"
          :> Description "Delete a comment for an article"
          :> Tag "Articles"
          :> Delete '[JSON] S.NoContent
  -- ^ DELETE /api/articles/:slug/comments/:id
  }
  deriving stock (Generic)

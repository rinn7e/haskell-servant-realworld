module Api.Article.Admin.Handler where

import Data.Map.Append (unAppendMap)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Time (getCurrentTime)
import Database.Persist (delete, deleteWhere, insert, (==.))
import Database.Persist.Sql (Entity (..))
import Effectful (liftIO)
import Effectful.Error.Static (throwError)
import Servant (NamedRoutes)
import Servant qualified as S
import Servant.Auth.Server qualified as S

import Api.Admin.Guard (guardAdmin)
import Api.Article.Admin.Type
import Common.Type.App (App)
import DB.Schema.Type (UserId)
import DB.Schema.Type qualified as DB
import DB.Util (runDB)
import Entity.Article.Api
  ( ArticleListResponse (..)
  , toArticleResponse
  )
import Entity.Article.Query

adminArticleRoute :: S.AuthResult UserId -> S.ServerT (NamedRoutes AdminArticleRoute) App
adminArticleRoute auth =
  AdminArticleRoute
    { getArticles = getArticlesHandler auth
    , deleteArticle = deleteArticleHandler auth
    }

getArticlesHandler
  :: S.AuthResult UserId
  -> Maybe Int
  -> Maybe Text
  -> Maybe Text
  -> App ArticleListResponse
getArticlesHandler (S.Authenticated uid) mPage mTag mAuthor = do
  guardAdmin uid
  let page = maybe 1 id mPage
      pageSize = 10
      offset = (page - 1) * pageSize

  runDB $ do
    groupedArticles <- listArticles Nothing mTag mAuthor Nothing pageSize offset
    totalCount <- countArticles mTag mAuthor Nothing
    let articles = map toArticleResponse $ Map.elems $ unAppendMap groupedArticles
    return $ ArticleListResponse articles totalCount
getArticlesHandler _ _ _ _ = throwError S.err401

deleteArticleHandler :: S.AuthResult UserId -> Text -> App S.NoContent
deleteArticleHandler (S.Authenticated uid) slug = do
  guardAdmin uid
  mArt <- runDB (getArticleBySlug slug)
  case mArt of
    Nothing -> throwError S.err404
    Just (Entity aid _) -> do
      now <- liftIO getCurrentTime
      runDB $ do
        deleteWhere [DB.ArticleTagArticleId ==. aid]
        deleteWhere [DB.CommentArticleId ==. aid]
        deleteWhere [DB.FavoriteArticleId ==. aid]
        delete aid
        -- Audit event log
        _ <- insert $ DB.Log "INFO" ("Deleted article: " <> slug) "ARTICLE" now (Just uid)
        return ()
      return S.NoContent
deleteArticleHandler _ _ = throwError S.err401

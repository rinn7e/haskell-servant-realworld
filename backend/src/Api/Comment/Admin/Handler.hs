module Api.Comment.Admin.Handler where

import Data.Text (Text)
import Data.Time (getCurrentTime)
import Database.Persist
  ( Filter
  , SelectOpt (..)
  , count
  , delete
  , get
  , insert
  , selectList
  )
import Database.Persist.Sql (Entity (..), fromSqlKey, toSqlKey)
import Effectful (liftIO)
import Effectful.Error.Static (throwError)
import Servant (NamedRoutes)
import Servant qualified as S
import Servant.Auth.Server qualified as S

import Api.Admin.Guard (guardAdmin)
import Api.Comment.Admin.Type
import Common.Type.App (App)
import DB.Schema.Type (UserId)
import DB.Schema.Type qualified as DB
import DB.Util (runDB)

adminCommentRoute :: S.AuthResult UserId -> S.ServerT (NamedRoutes AdminCommentRoute) App
adminCommentRoute auth =
  AdminCommentRoute
    { getComments = getCommentsHandler auth
    , deleteComment = deleteCommentHandler auth
    }

getCommentsHandler :: S.AuthResult UserId -> Maybe Int -> App AdminCommentListResponse
getCommentsHandler (S.Authenticated uid) mPage = do
  guardAdmin uid
  let page = maybe 1 id mPage
      pageSize = 10
      offset = (page - 1) * pageSize

  runDB $ do
    totalCount <- fromIntegral <$> count ([] :: [Filter DB.Comment])
    entities <- selectList [] [Desc DB.CommentCreatedAt, LimitTo pageSize, OffsetTo offset]
    comments <- forM entities $ \(Entity cid c) -> do
      mArt <- get c.articleId
      mUser <- get c.authorId
      let slug = maybe "" (\art -> art.slug) mArt
          username = maybe "" (\u -> u.username) mUser
      return AdminCommentResponse
        { id = fromIntegral (fromSqlKey cid)
        , body = c.body
        , createdAt = c.createdAt
        , articleSlug = slug
        , authorUsername = username
        }
    return AdminCommentListResponse
      { comments = comments
      , totalCount = totalCount
      }
  where
    forM = flip mapM
getCommentsHandler _ _ = throwError S.err401

deleteCommentHandler :: S.AuthResult UserId -> Int -> App S.NoContent
deleteCommentHandler (S.Authenticated uid) cidInt = do
  guardAdmin uid
  let cid = toSqlKey (fromIntegral cidInt)
  mTarget <- runDB (get cid)
  case mTarget of
    Nothing -> throwError S.err404
    Just target -> do
      now <- liftIO getCurrentTime
      runDB $ do
        delete cid
        _ <- insert $ DB.Log "INFO" ("Deleted comment: " <> target.body) "COMMENT" now (Just uid)
        return ()
      return S.NoContent
deleteCommentHandler _ _ = throwError S.err401

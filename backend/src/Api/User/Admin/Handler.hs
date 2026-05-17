module Api.User.Admin.Handler where

import Data.Text (Text)
import Data.Time (getCurrentTime)
import Database.Persist
  ( Filter
  , SelectOpt (..)
  , (==.)
  , count
  , delete
  , deleteWhere
  , get
  , insert
  , replace
  , selectList
  )
import Database.Persist.Sql (Entity (..), fromSqlKey, toSqlKey)
import Effectful (liftIO)
import Effectful.Error.Static (throwError)
import Servant (NamedRoutes)
import Servant qualified as S
import Servant.Auth.Server qualified as S

import Api.Admin.Guard (guardAdmin)
import Api.User.Admin.Type
import Common.Type.App (App)
import DB.Schema.Type (UserId)
import DB.Schema.Type qualified as DB
import DB.Util (runDB)

adminUserRoute :: S.AuthResult UserId -> S.ServerT (NamedRoutes AdminUserRoute) App
adminUserRoute auth =
  AdminUserRoute
    { getUsers = getUsersHandler auth
    , updateUserRole = updateUserRoleHandler auth
    , deleteUser = deleteUserHandler auth
    }

getUsersHandler :: S.AuthResult UserId -> Maybe Int -> App AdminUserListResponse
getUsersHandler (S.Authenticated uid) mPage = do
  guardAdmin uid
  let page = maybe 1 id mPage
      pageSize = 10
      offset = (page - 1) * pageSize

  runDB $ do
    totalCount <- fromIntegral <$> count ([] :: [Filter DB.User])
    entities <- selectList [] [Asc DB.UserUsername, LimitTo pageSize, OffsetBy offset]
    let users = map toAdminUserResponse entities
    return AdminUserListResponse
      { users = users
      , totalCount = totalCount
      }
getUsersHandler _ _ = throwError S.err401

updateUserRoleHandler :: S.AuthResult UserId -> Int -> UpdateUserRoleRequest -> App AdminUserResponse
updateUserRoleHandler (S.Authenticated uid) targetUidInt req = do
  guardAdmin uid
  let targetUid = toSqlKey (fromIntegral targetUidInt)
  mTarget <- runDB (get targetUid)
  case mTarget of
    Nothing -> throwError S.err404
    Just target -> do
      now <- liftIO getCurrentTime
      let updatedUser = target { DB.role = req.role }
      runDB $ do
        replace targetUid updatedUser
        _ <- insert $ DB.Log "INFO" ("Updated user role for " <> target.username <> " to " <> req.role) "AUTH" now (Just uid)
        return ()
      return $ toAdminUserResponse (Entity targetUid updatedUser)
updateUserRoleHandler _ _ _ = throwError S.err401

deleteUserHandler :: S.AuthResult UserId -> Int -> App S.NoContent
deleteUserHandler (S.Authenticated uid) targetUidInt = do
  guardAdmin uid
  let targetUid = toSqlKey (fromIntegral targetUidInt)
  mTarget <- runDB (get targetUid)
  case mTarget of
    Nothing -> throwError S.err404
    Just target -> do
      now <- liftIO getCurrentTime
      runDB $ do
        -- 1. Clean up articles authored by this user
        articles <- selectList [DB.ArticleAuthorId ==. targetUid] []
        forM_ articles $ \(Entity aid _) -> do
          deleteWhere [DB.ArticleTagArticleId ==. aid]
          deleteWhere [DB.CommentArticleId ==. aid]
          deleteWhere [DB.FavoriteArticleId ==. aid]
        deleteWhere [DB.ArticleAuthorId ==. targetUid]

        -- 2. Clean up comments authored by this user
        deleteWhere [DB.CommentAuthorId ==. targetUid]

        -- 3. Clean up favorites/likes cast by this user
        deleteWhere [DB.FavoriteUserId ==. targetUid]

        -- 4. Clean up followers and followed associations
        deleteWhere [DB.FollowFollowerId ==. targetUid]
        deleteWhere [DB.FollowFollowedId ==. targetUid]

        -- 5. Ban the actual user record
        delete targetUid

        -- 6. Log the audit event
        _ <- insert $ DB.Log "INFO" ("Banned/Deleted user account: " <> target.username) "AUTH" now (Just uid)
        return ()

      return S.NoContent
  where
    forM_ = flip mapM_
deleteUserHandler _ _ = throwError S.err401

toAdminUserResponse :: Entity DB.User -> AdminUserResponse
toAdminUserResponse (Entity uid u) = AdminUserResponse
  { id = fromIntegral (fromSqlKey uid)
  , username = u.username
  , email = u.email
  , bio = u.bio
  , image = u.image
  , role = u.role
  }

module Api.Util where

import Data.Map.Append (unAppendMap)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.Semigroup (First (..))
import Database.Persist.Sql (Entity (..), SqlPersistT, fromSqlKey)

import Api.Type (ArticleResponse (..), CommentResponse (..), ProfileResponse (..))
import Common.Type.App (AppEnv)
import DB.Article.Type (ArticleGrouped)
import DB.Follow.Query (isFollowing)
import DB.Schema.Type (UserId)
import DB.Schema.Type qualified as DB

toArticleResponse :: ArticleGrouped -> ArticleResponse
toArticleResponse (First (Entity _ art), First (Entity _ author), tagsMap, (First favCount, First isFav, First isFol)) =
  let tags = map (\(First t) -> t.entityVal.name) $ Map.elems $ unAppendMap tagsMap
      profile = ProfileResponse author.username author.bio author.image isFol
   in ArticleResponse art.slug art.title art.description art.body tags art.createdAt art.updatedAt isFav (fromMaybe 0 favCount) profile

toCommentResponse :: AppEnv -> Maybe UserId -> (Entity DB.Comment, Entity DB.User) -> SqlPersistT IO CommentResponse
toCommentResponse _ mCurrentUserId (Entity cid comm, Entity _ author) = do
  isFol <- case mCurrentUserId of
    Just uid -> isFollowing uid comm.authorId
    Nothing -> return False

  let profile = ProfileResponse author.username author.bio author.image isFol
  return $ CommentResponse (fromIntegral (fromSqlKey cid)) comm.createdAt comm.updatedAt comm.body profile

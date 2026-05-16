module Entity.Comment.Query where

import Database.Esqueleto.Experimental
import UnliftIO (MonadUnliftIO)

import DB.Schema.Type

getCommentsForArticle
  :: (MonadUnliftIO m) => ArticleId -> SqlPersistT m [(Entity Comment, Entity User)]
getCommentsForArticle aid = fmap (map (\(c :& u) -> (c, u))) $ select $ getCommentsForArticleSQL aid

getCommentsForArticleSQL
  :: ArticleId -> SqlQuery (SqlExpr (Entity Comment) :& SqlExpr (Entity User))
getCommentsForArticleSQL aid = do
  (comment :& author) <-
    from $
      table @Comment
        `innerJoin` table @User `on` (\(c :& u) -> c ^. CommentAuthorId ==. u ^. UserId)
  where_ (comment ^. CommentArticleId ==. val aid)
  orderBy [desc (comment ^. CommentCreatedAt)]
  return (comment :& author)

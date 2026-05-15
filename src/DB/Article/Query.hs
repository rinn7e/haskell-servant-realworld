{-# LANGUAGE TypeApplications #-}

module DB.Article.Query where

import Control.Monad (when)
import Data.Foldable (for_)
import Data.Map.Append (unAppendMap)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Database.Esqueleto.Experimental
import UnliftIO (MonadUnliftIO)

import DB.Article.Type
import DB.Follow.Query (isFollowing)
import DB.Schema.Type

getArticleBySlug :: (MonadUnliftIO m) => Text -> SqlPersistT m (Maybe (Entity Article))
getArticleBySlug slug = selectOne $ getArticleBySlugSQL slug

-- | Fetch a single article entity by its slug
getArticleBySlugSQL :: Text -> SqlQuery (SqlExpr (Entity Article))
getArticleBySlugSQL slug = do
  article <- from $ table @Article
  where_ (article ^. ArticleSlug ==. val slug)
  return article

getArticleWithAuthor :: (MonadUnliftIO m) => Maybe UserId -> Text -> SqlPersistT m (Maybe ArticleGrouped)
getArticleWithAuthor mCurrentUserId slug = do
  result <- select $ getArticleWithAuthorSQL mCurrentUserId slug
  return $ headMay $ Map.elems $ unAppendMap $ mconcat $ map mkArticleGrouped result
 where
  headMay (x : _) = Just x
  headMay [] = Nothing

-- | Main query to fetch an article with its author, tags, and metadata
getArticleWithAuthorSQL
  :: Maybe UserId
  -> Text -> SqlQuery ArticleExpr
getArticleWithAuthorSQL mCurrentUserId slug = do
  (((article :& author) :& articleTag) :& tag) <-
    from $
      table @Article
        `innerJoin` table @User `on` (\(art :& auth) -> art ^. ArticleAuthorId ==. auth ^. UserId)
        `leftJoin` table @ArticleTag `on` (\(art :& _ :& at) -> just (art ^. ArticleId) ==. at ?. ArticleTagArticleId)
        `leftJoin` table @Tag `on` (\(_ :& _ :& at :& t) -> at ?. ArticleTagTagId ==. t ?. TagId)
  where_ (article ^. ArticleSlug ==. val slug)

  return
    ( article
    , author
    , tag
    , countFavoritesExpr (article ^. ArticleId)
    , case mCurrentUserId of
        Just uid -> isFavoritedByExpr (article ^. ArticleId) (val uid)
        Nothing -> val False
    , case mCurrentUserId of
        Just uid -> isFollowingUserExpr (author ^. UserId) (val uid)
        Nothing -> val False
    )

listArticles
  :: Maybe UserId
  -> Maybe Text
  -> Maybe Text
  -> Maybe Text
  -> Int
  -> Int
  -> SqlPersistT IO [ArticleGrouped]
listArticles mCurrentUserId mTag mAuthor mFavorited lim off = do
  result <- select $ listArticlesSQL mCurrentUserId mTag mAuthor mFavorited lim off
  return $ Map.elems $ unAppendMap $ mconcat $ map mkArticleGrouped result

-- | Main query to list articles with filtering and pagination
listArticlesSQL
  :: Maybe UserId
  -> Maybe Text
  -> Maybe Text
  -> Maybe Text
  -> Int
  -> Int -> SqlQuery ArticleExpr
listArticlesSQL mCurrentUserId mTag mAuthor mFavorited lim off = do
  (((article :& author) :& articleTag) :& tag) <-
    from $
      table @Article
        `innerJoin` table @User `on` (\(art :& auth) -> art ^. ArticleAuthorId ==. auth ^. UserId)
        `leftJoin` table @ArticleTag `on` (\(art :& _ :& at) -> just (art ^. ArticleId) ==. at ?. ArticleTagArticleId)
        `leftJoin` table @Tag `on` (\(_ :& _ :& at :& t) -> at ?. ArticleTagTagId ==. t ?. TagId)

  where_ (article ^. ArticleId `in_` subList_select (filterArticlesIdsSQL mTag mAuthor mFavorited lim off))

  return
    ( article
    , author
    , tag
    , countFavoritesExpr (article ^. ArticleId)
    , case mCurrentUserId of
        Just uid -> isFavoritedByExpr (article ^. ArticleId) (val uid)
        Nothing -> val False
    , case mCurrentUserId of
        Just uid -> isFollowingUserExpr (author ^. UserId) (val uid)
        Nothing -> val False
    )

listFeed :: (MonadUnliftIO m) => UserId -> Int -> Int -> SqlPersistT m [ArticleGrouped]
listFeed currentUserId lim off = do
  result <- select $ listFeedSQL currentUserId lim off
  return $ Map.elems $ unAppendMap $ mconcat $ map mkArticleGrouped result

-- | Main query to fetch the article feed for a user
listFeedSQL
  :: UserId
  -> Int
  -> Int -> SqlQuery ArticleExpr
listFeedSQL currentUserId lim off = do
  (((article :& author) :& articleTag) :& tag) <-
    from $
      table @Article
        `innerJoin` table @User `on` (\(art :& auth) -> art ^. ArticleAuthorId ==. auth ^. UserId)
        `leftJoin` table @ArticleTag `on` (\(art :& _ :& at) -> just (art ^. ArticleId) ==. at ?. ArticleTagArticleId)
        `leftJoin` table @Tag `on` (\(_ :& _ :& at :& t) -> at ?. ArticleTagTagId ==. t ?. TagId)

  where_ (article ^. ArticleId `in_` subList_select (feedArticlesIdsSQL currentUserId lim off))

  return
    ( article
    , author
    , tag
    , countFavoritesExpr (article ^. ArticleId)
    , isFavoritedByExpr (article ^. ArticleId) (val currentUserId)
    , isFollowingUserExpr (author ^. UserId) (val currentUserId)
    )

-- | Subquery to filter article IDs by tags, author, and favorites
filterArticlesIdsSQL
  :: Maybe Text
  -> Maybe Text
  -> Maybe Text
  -> Int
  -> Int
  -> SqlQuery (SqlExpr (Value ArticleId))
filterArticlesIdsSQL mTag mAuthor mFavorited lim off = do
  article <- from $ table @Article
  author <- from $ table @User
  where_ (article ^. ArticleAuthorId ==. author ^. UserId)

  for_ mTag \tag -> where_ $ exists $ do
    (at :& t) <-
      from $
        table @ArticleTag
          `innerJoin` table @Tag `on` (\(at :& t) -> at ^. ArticleTagTagId ==. t ^. TagId)
    where_ (at ^. ArticleTagArticleId ==. article ^. ArticleId)
    where_ (t ^. TagName ==. val tag)

  for_ mAuthor \authName -> where_ (author ^. UserUsername ==. val authName)

  for_ mFavorited \favName -> where_ $ exists $ do
    (fav :& uFav) <-
      from $
        table @Favorite
          `innerJoin` table @User `on` (\(fav :& u) -> fav ^. FavoriteUserId ==. u ^. UserId)
    where_ (fav ^. FavoriteArticleId ==. article ^. ArticleId)
    where_ (uFav ^. UserUsername ==. val favName)

  orderBy [desc (article ^. ArticleCreatedAt)]
  when (lim > 0) $ limit (fromIntegral lim)
  when (off > 0) $ offset (fromIntegral off)
  return (article ^. ArticleId)

-- | Subquery to fetch article IDs from followed authors for the feed
feedArticlesIdsSQL
  :: UserId
  -> Int
  -> Int
  -> SqlQuery (SqlExpr (Value ArticleId))
feedArticlesIdsSQL currentUserId lim off = do
  ((article :& author) :& follow) <-
    from $
      table @Article
        `innerJoin` table @User `on` (\(art :& auth) -> art ^. ArticleAuthorId ==. auth ^. UserId)
        `innerJoin` table @Follow `on` (\(_ :& auth :& f) -> f ^. FollowFollowedId ==. auth ^. UserId)
  where_ (follow ^. FollowFollowerId ==. val currentUserId)
  orderBy [desc (article ^. ArticleCreatedAt)]
  when (lim > 0) $ limit (fromIntegral lim)
  when (off > 0) $ offset (fromIntegral off)
  return (article ^. ArticleId)

-- | Expression to count favorites for an article
countFavoritesExpr :: SqlExpr (Value ArticleId) -> SqlExpr (Value (Maybe Int))
countFavoritesExpr aid = subSelect $ do
  fav <- from $ table @Favorite
  where_ (fav ^. FavoriteArticleId ==. aid)
  pure countRows

-- | Expression to check if a user has favorited an article
isFavoritedByExpr :: SqlExpr (Value ArticleId) -> SqlExpr (Value UserId) -> SqlExpr (Value Bool)
isFavoritedByExpr aid uid = exists $ do
  fav <- from $ table @Favorite
  where_ (fav ^. FavoriteArticleId ==. aid)
  where_ (fav ^. FavoriteUserId ==. uid)

-- | Expression to check if a follower is following an author
isFollowingUserExpr :: SqlExpr (Value UserId) -> SqlExpr (Value UserId) -> SqlExpr (Value Bool)
isFollowingUserExpr authorId followerId = exists $ do
  fol <- from $ table @Follow
  where_ (fol ^. FollowFollowedId ==. authorId)
  where_ (fol ^. FollowFollowerId ==. followerId)

getArticleTags :: (MonadUnliftIO m) => ArticleId -> SqlPersistT m [Text]
getArticleTags aid = map unValue <$> select (getArticleTagsSQL aid)

-- | Query to fetch all tag names for a specific article
getArticleTagsSQL :: ArticleId -> SqlQuery (SqlExpr (Value Text))
getArticleTagsSQL aid = do
  (at :& t) <-
    from $
      table @ArticleTag
        `innerJoin` table @Tag `on` (\(at :& t) -> at ^. ArticleTagTagId ==. t ^. TagId)
  where_ (at ^. ArticleTagArticleId ==. val aid)
  return (t ^. TagName)

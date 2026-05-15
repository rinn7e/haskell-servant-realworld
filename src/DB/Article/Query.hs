module DB.Article.Query where

import Control.Monad (when)
import Data.Foldable (for_)
import Data.Map.Append (AppendMap (..))
import Data.Map.Strict qualified as Map
import Data.Ord (Down (..))
import Data.Semigroup (First (..))
import Data.Text (Text)
import Data.Time (UTCTime)
import Database.Esqueleto.Experimental
import UnliftIO (MonadUnliftIO)

import DB.Article.Type
import DB.Schema.Type

getArticleBySlug :: (MonadUnliftIO m) => Text -> SqlPersistT m (Maybe (Entity Article))
getArticleBySlug slug = selectOne $ getArticleBySlugSQL slug

getArticleBySlugSQL :: Text -> SqlQuery (SqlExpr (Entity Article))
getArticleBySlugSQL slug = do
  article <- from $ table @Article
  where_ (article ^. ArticleSlug ==. val slug)
  return article

getArticleWithAuthor :: (MonadUnliftIO m) => Maybe UserId -> Text -> SqlPersistT m (Maybe ArticleGroupedType)
getArticleWithAuthor mCurrentUserId slug = do
  result <- select $ getArticleWithAuthorSQL mCurrentUserId slug
  return $ headMay $ Map.elems $ unAppendMap $ mconcat $ map mkArticleGrouped result
 where
  headMay (x : _) = Just x
  headMay [] = Nothing

getArticleWithAuthorSQL
  :: Maybe UserId
  -> Text
  -> SqlQuery
      ( SqlExpr (Entity Article)
      , SqlExpr (Entity User)
      , SqlExpr (Maybe (Entity Tag))
      , SqlExpr (Value (Maybe Int))
      , SqlExpr (Value Bool)
      , SqlExpr (Value Bool)
      )
getArticleWithAuthorSQL mCurrentUserId slug = do
  (((article :& author) :& articleTag) :& tag) <-
    from $
      table @Article
        `innerJoin` table @User `on` (\(art :& auth) -> art ^. ArticleAuthorId ==. auth ^. UserId)
        `leftJoin` table @ArticleTag `on` (\(art :& _ :& at) -> just (art ^. ArticleId) ==. at ?. ArticleTagArticleId)
        `leftJoin` table @Tag `on` (\(_ :& _ :& at :& t) -> at ?. ArticleTagTagId ==. t ?. TagId)
  where_ (article ^. ArticleSlug ==. val slug)

  let favCount = subSelect $ do
        fav <- from $ table @Favorite
        where_ (fav ^. FavoriteArticleId ==. article ^. ArticleId)
        pure countRows

  let isFav = case mCurrentUserId of
        Just uid -> exists $ do
          fav <- from $ table @Favorite
          where_ (fav ^. FavoriteArticleId ==. article ^. ArticleId)
          where_ (fav ^. FavoriteUserId ==. val uid)
        Nothing -> val False

  let isFol = case mCurrentUserId of
        Just uid -> exists $ do
          fol <- from $ table @Follow
          where_ (fol ^. FollowFollowedId ==. author ^. UserId)
          where_ (fol ^. FollowFollowerId ==. val uid)
        Nothing -> val False

  return (article, author, tag, favCount, isFav, isFol)

listArticles
  :: Maybe UserId
  -> Maybe Text
  -> Maybe Text
  -> Maybe Text
  -> Int
  -> Int
  -> SqlPersistT IO [(ArticleGroupedType)]
listArticles mCurrentUserId mTag mAuthor mFavorited lim off = do
  result <- select $ listArticlesSQL mCurrentUserId mTag mAuthor mFavorited lim off
  return $ Map.elems $ unAppendMap $ mconcat $ map mkArticleGrouped result

listArticlesSQL
  :: Maybe UserId
  -> Maybe Text
  -> Maybe Text
  -> Maybe Text
  -> Int
  -> Int
  -> SqlQuery
      ( SqlExpr (Entity Article)
      , SqlExpr (Entity User)
      , SqlExpr (Maybe (Entity Tag))
      , SqlExpr (Value (Maybe Int))
      , SqlExpr (Value Bool)
      , SqlExpr (Value Bool)
      )
listArticlesSQL mCurrentUserId mTag mAuthor mFavorited lim off = do
  -- Subquery for filtered and paginated article IDs
  let articleIdsQuery = do
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

  (((article :& author) :& articleTag) :& tag) <-
    from $
      table @Article
        `innerJoin` table @User `on` (\(art :& auth) -> art ^. ArticleAuthorId ==. auth ^. UserId)
        `leftJoin` table @ArticleTag `on` (\(art :& _ :& at) -> just (art ^. ArticleId) ==. at ?. ArticleTagArticleId)
        `leftJoin` table @Tag `on` (\(_ :& _ :& at :& t) -> at ?. ArticleTagTagId ==. t ?. TagId)

  where_ (article ^. ArticleId `in_` subList_select articleIdsQuery)

  let favCount = subSelect $ do
        fav <- from $ table @Favorite
        where_ (fav ^. FavoriteArticleId ==. article ^. ArticleId)
        pure countRows

  let isFav = case mCurrentUserId of
        Just uid -> exists $ do
          fav <- from $ table @Favorite
          where_ (fav ^. FavoriteArticleId ==. article ^. ArticleId)
          where_ (fav ^. FavoriteUserId ==. val uid)
        Nothing -> val False

  let isFol = case mCurrentUserId of
        Just uid -> exists $ do
          fol <- from $ table @Follow
          where_ (fol ^. FollowFollowedId ==. author ^. UserId)
          where_ (fol ^. FollowFollowerId ==. val uid)
        Nothing -> val False

  return (article, author, tag, favCount, isFav, isFol)

listFeed :: (MonadUnliftIO m) => UserId -> Int -> Int -> SqlPersistT m [ArticleGroupedType]
listFeed currentUserId lim off = do
  result <- select $ listFeedSQL currentUserId lim off
  return $ Map.elems $ unAppendMap $ mconcat $ map mkArticleGrouped result

listFeedSQL
  :: UserId
  -> Int
  -> Int
  -> SqlQuery
      ( SqlExpr (Entity Article)
      , SqlExpr (Entity User)
      , SqlExpr (Maybe (Entity Tag))
      , SqlExpr (Value (Maybe Int))
      , SqlExpr (Value Bool)
      , SqlExpr (Value Bool)
      )
listFeedSQL currentUserId lim off = do
  -- Subquery for filtered and paginated article IDs
  let articleIdsQuery = do
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

  (((article :& author) :& articleTag) :& tag) <-
    from $
      table @Article
        `innerJoin` table @User `on` (\(art :& auth) -> art ^. ArticleAuthorId ==. auth ^. UserId)
        `leftJoin` table @ArticleTag `on` (\(art :& _ :& at) -> just (art ^. ArticleId) ==. at ?. ArticleTagArticleId)
        `leftJoin` table @Tag `on` (\(_ :& _ :& at :& t) -> at ?. ArticleTagTagId ==. t ?. TagId)

  where_ (article ^. ArticleId `in_` subList_select articleIdsQuery)

  let favCount = subSelect $ do
        fav <- from $ table @Favorite
        where_ (fav ^. FavoriteArticleId ==. article ^. ArticleId)
        pure countRows

  let isFav = exists $ do
        fav <- from $ table @Favorite
        where_ (fav ^. FavoriteArticleId ==. article ^. ArticleId)
        where_ (fav ^. FavoriteUserId ==. val currentUserId)

  let isFol = exists $ do
        fol <- from $ table @Follow
        where_ (fol ^. FollowFollowedId ==. author ^. UserId)
        where_ (fol ^. FollowFollowerId ==. val currentUserId)

  return (article, author, tag, favCount, isFav, isFol)

getArticleTags :: (MonadUnliftIO m) => ArticleId -> SqlPersistT m [Text]
getArticleTags aid = map unValue <$> select (getArticleTagsSQL aid)

getArticleTagsSQL :: ArticleId -> SqlQuery (SqlExpr (Value Text))
getArticleTagsSQL aid = do
  (at :& t) <-
    from $
      table @ArticleTag
        `innerJoin` table @Tag `on` (\(at :& t) -> at ^. ArticleTagTagId ==. t ^. TagId)
  where_ (at ^. ArticleTagArticleId ==. val aid)
  return (t ^. TagName)

isArticleFavorited :: (MonadUnliftIO m) => ArticleId -> UserId -> SqlPersistT m Bool
isArticleFavorited aid uid = maybe False (const True) <$> selectOne (isArticleFavoritedSQL aid uid)

isArticleFavoritedSQL :: ArticleId -> UserId -> SqlQuery (SqlExpr (Value FavoriteId))
isArticleFavoritedSQL aid uid = do
  fav <- from $ table @Favorite
  where_ (fav ^. FavoriteArticleId ==. val aid)
  where_ (fav ^. FavoriteUserId ==. val uid)
  return (fav ^. FavoriteId)

getFavoritesCount :: (MonadUnliftIO m) => ArticleId -> SqlPersistT m Int
getFavoritesCount aid = maybe 0 unValue . headMay <$> select (getFavoritesCountSQL aid)
 where
  headMay (x : _) = Just x
  headMay [] = Nothing

getFavoritesCountSQL :: ArticleId -> SqlQuery (SqlExpr (Value Int))
getFavoritesCountSQL aid = do
  fav <- from $ table @Favorite
  where_ (fav ^. FavoriteArticleId ==. val aid)
  return countRows

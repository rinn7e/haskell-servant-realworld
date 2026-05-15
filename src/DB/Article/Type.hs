module DB.Article.Type where

import Data.Map.Append (AppendMap (..))
import Data.Map.Strict qualified as Map
import Data.Ord (Down (..))
import Data.Semigroup (First (..))
import Data.Time (UTCTime)
import Database.Esqueleto.Experimental

import DB.Schema.Type

type ArticleSQLType =
  ( Entity Article
  , Entity User -- author
  , Maybe (Entity Tag)
  , Value (Maybe Int) -- favorites count
  , Value Bool -- is favorited by current user
  , Value Bool -- is following author
  )

type ArticleGroupedType =
  ( First (Entity Article)
  , First (Entity User)
  , AppendMap TagId (First (Entity Tag))
  , ( First (Maybe Int)
    , First Bool
    , First Bool
    )
  )

mkArticleGrouped :: ArticleSQLType -> AppendMap (Down UTCTime, ArticleId) ArticleGroupedType
mkArticleGrouped (art, auth, mTag, Value favCount, Value isFav, Value isFol) =
  AppendMap $
    Map.singleton
      (Down art.entityVal.createdAt, art.entityKey)
      ( First art
      , First auth
      , case mTag of
          Just t -> AppendMap $ Map.singleton t.entityKey (First t)
          Nothing -> AppendMap Map.empty
      , ( First favCount
        , First isFav
        , First isFol
        )
      )

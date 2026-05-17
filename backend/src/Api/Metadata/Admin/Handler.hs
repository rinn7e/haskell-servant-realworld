module Api.Metadata.Admin.Handler where

import Data.Text (Text)
import Data.Time (UTCTime, addUTCTime, getCurrentTime)
import Database.Persist
  ( Filter
  , SelectOpt (..)
  , (==.), (!=.)
  , count
  , selectList
  )
import Database.Persist.Sql (Entity (..), fromSqlKey)
import Effectful (liftIO)
import Effectful.Error.Static (throwError)
import Servant (NamedRoutes)
import Servant qualified as S
import Servant.Auth.Server qualified as S

import Api.Admin.Guard (guardAdmin)
import Api.Metadata.Admin.Type
import Common.Type.App (App)
import DB.Schema.Type (UserId)
import DB.Schema.Type qualified as DB
import DB.Util (runDB)
import Entity.Dashboard.Api (DashboardStatsResponse (..))
import Entity.Log.Api (LogListResponse (..), LogResponse (..))
import Entity.Visitor.Api (VisitorListResponse (..), VisitorResponse (..))

adminMetadataRoute :: S.AuthResult UserId -> S.ServerT (NamedRoutes AdminMetadataRoute) App
adminMetadataRoute auth =
  AdminMetadataRoute
    { getDashboardStats = getDashboardStatsHandler auth
    , getLogs = getLogsHandler auth
    , getVisitors = getVisitorsHandler auth
    }

getDashboardStatsHandler :: S.AuthResult UserId -> App DashboardStatsResponse
getDashboardStatsHandler (S.Authenticated uid) = do
  guardAdmin uid
  now <- liftIO getCurrentTime
  let oneDayAgo = addUTCTime (-86400) now

  runDB $ do
    totalUsers <- fromIntegral <$> count ([] :: [Filter DB.User])
    totalArticles <- fromIntegral <$> count ([] :: [Filter DB.Article])
    totalComments <- fromIntegral <$> count ([] :: [Filter DB.Comment])
    totalVisitors <- fromIntegral <$> count ([] :: [Filter DB.Visitor])

    -- Simple estimation: count visitors who hit within last 24h
    activeUsers24h <- fromIntegral <$> count [DB.VisitorTimestamp >=. oneDayAgo]

    return DashboardStatsResponse
      { totalUsers = totalUsers
      , totalArticles = totalArticles
      , totalComments = totalComments
      , totalVisitors = totalVisitors
      , activeUsers24h = if activeUsers24h == 0 then totalUsers else activeUsers24h
      }
getDashboardStatsHandler _ = throwError S.err401

getLogsHandler
  :: S.AuthResult UserId -> Maybe Int -> Maybe Text -> Maybe Text -> App LogListResponse
getLogsHandler (S.Authenticated uid) mPage mLevel mSource = do
  guardAdmin uid
  let page = maybe 1 id mPage
      pageSize = 10
      offset = (page - 1) * pageSize

  let filters = concat
        [ maybe [] (\lvl -> [DB.LogLevel ==. lvl]) mLevel
        , maybe [] (\src -> [DB.LogSource ==. src]) mSource
        ]

  runDB $ do
    totalCount <- fromIntegral <$> count filters
    entities <- selectList filters [Desc DB.LogTimestamp, LimitTo pageSize, OffsetTo offset]
    let logs = map toLogResponse entities
    return LogListResponse
      { logs = logs
      , totalCount = totalCount
      }
  where
    toLogResponse :: Entity DB.Log -> LogResponse
    toLogResponse (Entity lid l) = LogResponse
      { id = fromIntegral (fromSqlKey lid)
      , level = l.level
      , message = l.message
      , source = l.source
      , timestamp = l.timestamp
      , userId = fmap (fromIntegral . fromSqlKey) l.userId
      }
getLogsHandler _ _ _ _ = throwError S.err401

getVisitorsHandler :: S.AuthResult UserId -> Maybe Int -> Maybe Text -> App VisitorListResponse
getVisitorsHandler (S.Authenticated uid) mPage mIp = do
  guardAdmin uid
  let page = maybe 1 id mPage
      pageSize = 10
      offset = (page - 1) * pageSize

  let filters = maybe [] (\ip -> [DB.VisitorIp ==. ip]) mIp

  runDB $ do
    totalCount <- fromIntegral <$> count filters
    entities <- selectList filters [Desc DB.VisitorTimestamp, LimitTo pageSize, OffsetTo offset]
    let visitors = map toVisitorResponse entities
    return VisitorListResponse
      { visitors = visitors
      , totalCount = totalCount
      }
  where
    toVisitorResponse :: Entity DB.Visitor -> VisitorResponse
    toVisitorResponse (Entity vid v) = VisitorResponse
      { id = fromIntegral (fromSqlKey vid)
      , ip = v.ip
      , userAgent = v.userAgent
      , path = v.path
      , timestamp = v.timestamp
      }
getVisitorsHandler _ _ _ = throwError S.err401

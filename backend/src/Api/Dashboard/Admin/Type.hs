module Api.Dashboard.Admin.Type where

import Data.Text (Text)
import GHC.Generics (Generic)
import Servant
  ( Description
  , GenericMode (type (:-))
  , Get
  , JSON
  , QueryParam
  , Summary
  , (:>)
  )

import Api.TagCombinator (Tag)
import Entity.Dashboard.Api (DashboardStatsResponse)
import Entity.Log.Api (LogListResponse)
import Entity.Visitor.Api (VisitorListResponse)

data AdminDashboardRoute mode = AdminDashboardRoute
  { getDashboardStats
      :: mode
        :- "dashboard"
          :> "stats"
          :> Summary "Get Dashboard Stats"
          :> Description "Get dashboard card and visitor metrics"
          :> Tag "Admin Dashboard"
          :> Get '[JSON] DashboardStatsResponse
  , getLogs
      :: mode
        :- "logs"
          :> Summary "Get System Logs"
          :> Description "Get paginated system audit and moderator logs"
          :> Tag "Admin Dashboard"
          :> QueryParam "page" Int
          :> QueryParam "level" Text
          :> QueryParam "source" Text
          :> Get '[JSON] LogListResponse
  , getVisitors
      :: mode
        :- "visitors"
          :> Summary "Get Visitor Logs"
          :> Description "Get paginated visitor traffic records"
          :> Tag "Admin Dashboard"
          :> QueryParam "page" Int
          :> QueryParam "ip" Text
          :> Get '[JSON] VisitorListResponse
  }
  deriving stock (Generic)

{-# LANGUAGE OverloadedRecordDot #-}

module Api.Route.Metadata where

import Data.Text qualified as T
import Data.Version (showVersion)
import GHC.Generics (Generic)
import Servant (GenericMode (type (:-)), Get, JSON, NamedRoutes)
import Servant qualified as S
import Servant.Auth.Server qualified as S

import Api.Type (Metadata (..))
import Common.Type.App (App, AppEnv (..))
import Common.Type.Config (Config (..))
import DB.Migration (getLastRanMigration)
import DB.Schema.Type (UserId)
import DB.Util (runDB)
import Effectful.Reader.Static (ask)
import Paths_haskell_servant_realworld qualified as Paths

data MetadataRoutes mode = MetadataRoutes
  { metadata :: mode :- Get '[JSON] Metadata
  -- ^ GET /api/metadata
  }
  deriving stock (Generic)

metadataServer :: S.AuthResult UserId -> S.ServerT (NamedRoutes MetadataRoutes) App
metadataServer _auth =
  MetadataRoutes
    { metadata = metadataHandler
    }

metadataHandler :: App Metadata
metadataHandler = do
  AppEnv{appConfig = config} <- ask
  lastMigration <- runDB getLastRanMigration
  return $
    Metadata
      { appVersion = T.pack (showVersion Paths.version)
      , lastCommitHash = config.gitCommitHash
      , lastRanMigration = lastMigration
      }

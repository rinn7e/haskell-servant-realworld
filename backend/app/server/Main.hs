{-# LANGUAGE OverloadedRecordDot #-}

module Main where

import Control.Monad (forM_, when)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Logger (runNoLoggingT, runStdoutLoggingT)
import Data.ByteString qualified as BS
import Data.Proxy (Proxy (..))
import Data.Text qualified as T
import Database.Persist.Postgresql (createPostgresqlPool)
import Database.Persist.Sql (getMigration, runSqlPool)
import Network.Wai (Middleware, Request (..))
import Network.Wai.Handler.Warp (run)
import Network.Wai.Middleware.Cors
  ( CorsResourcePolicy (..)
  , cors
  , simpleCorsResourcePolicy
  )
import Network.Wai.Middleware.RequestLogger (logStdoutDev)
import Servant (Context (..))
import Servant qualified as S
import Servant.Auth.Server qualified as S

import RunServer (AppEnv (..), runServer)
import Common.Type.Config (Config (..), loadConfig)
import Common.Type.JWK (makeSecretKey)
import DB.Migration
  ( generateMigration
  , getPendingMigrations
  , runMigrationsDown
  , runMigrationsUp
  )
import DB.Schema.Type (migrateAll)
import Type

main :: IO ()
main = do
  config <- loadConfig

  pool <-
    if config.showSqlLog
      then runStdoutLoggingT $ createPostgresqlPool config.dbConnStr 10
      else runNoLoggingT $ createPostgresqlPool config.dbConnStr 10

  -- Check for schema mismatches
  runSqlPool
    ( do
        pending <- getPendingMigrations
        missing <- getMigration migrateAll

        let needsUpdate = not (null pending) || not (null missing)

        if not needsUpdate
          then liftIO $ putStrLn "Database schema is up to date."
          else
            if config.shouldRunMigrationAuto
              then do
                liftIO $ putStrLn "Applying automatic migrations..."
                runMigrationsUp
              -- Note: we don't automatically apply Persistent's migrateAll,
              -- we just use it for checking. Only SQL files are applied.
              else liftIO $ do
                putStrLn "****************************************************"
                putStrLn "WARNING: Database schema mismatch detected!"
                when (not $ null pending) $ do
                  putStrLn "Pending SQL migrations:"
                  mapM_ (putStrLn . ("  - " ++)) pending
                when (not $ null missing) $ do
                  putStrLn "Persistent schema changes needed:"
                  forM_ missing $ \sql -> liftIO (print sql)
                putStrLn "Run 'make migrate-up' or set SHOULD_RUN_MIGRATION_AUTOMATICALLY=true"
                putStrLn "****************************************************"
    )
    pool

  let jwtKey = makeSecretKey config.jwtSecret
      jwtSettings = S.defaultJWTSettings jwtKey
      cfg = jwtSettings :. S.defaultCookieSettings :. EmptyContext
      port = config.port

  let corsMiddleware = if config.allowCorsEnabled then allowCors else id

  putStrLn $ "Starting server on port " ++ show port
  run port $
    logStdoutDev $
      corsMiddleware $
        authMiddleware $
          S.serveWithContext api cfg (runServer (AppEnv pool jwtSettings jwtKey config))

api :: Proxy API
api = Proxy

authMiddleware :: Middleware
authMiddleware app req sendResponse =
  let headers = requestHeaders req
      newHeaders = case lookup "Authorization" headers of
        Just auth
          | "Token " `BS.isPrefixOf` auth ->
              ("Authorization", "Bearer " <> BS.drop 6 auth)
                : filter ((/= "Authorization") . fst) headers
        _ -> headers
   in app req{requestHeaders = newHeaders} sendResponse

appCorsResourcePolicy :: CorsResourcePolicy
appCorsResourcePolicy =
  CorsResourcePolicy
    { corsOrigins = Nothing
    , corsMethods = ["OPTIONS", "GET", "PUT", "POST", "DELETE"]
    , corsRequestHeaders = ["Authorization", "Content-Type"]
    , corsExposedHeaders = Nothing
    , corsMaxAge = Nothing
    , corsVaryOrigin = False
    , corsRequireOrigin = False
    , corsIgnoreFailures = False
    }

allowCors :: Middleware
allowCors = cors (const $ Just appCorsResourcePolicy)

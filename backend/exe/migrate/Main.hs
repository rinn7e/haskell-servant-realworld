module Main where

import Common.Type.Config (Config (..), loadConfig)
import Control.Monad (forM_, when)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Logger (runStdoutLoggingT)
import DB.Migration (generateMigration, getPendingMigrations, runMigrationsDown, runMigrationsUp)
import DB.Schema.Type (migrateAll)
import Data.Text qualified as T
import Database.Persist.Postgresql (createPostgresqlPool)
import Database.Persist.Sql (getMigration, runSqlPool)
import System.Environment (getArgs)
import System.Exit (exitFailure, exitSuccess)

main :: IO ()
main = do
  args <- getArgs
  config <- loadConfig

  pool <- runStdoutLoggingT $ createPostgresqlPool config.dbConnStr 10

  case args of
    ["up"] -> do
      runSqlPool runMigrationsUp pool
      putStrLn "Migrations completed."
      exitSuccess
    ["down"] -> do
      runSqlPool runMigrationsDown pool
      putStrLn "Migrations reverted."
      exitSuccess
    ["check"] -> do
      runSqlPool
        ( do
            pending <- getPendingMigrations
            missing <- getMigration migrateAll

            let needsUpdate = not (null pending) || not (null missing)

            if not needsUpdate
              then liftIO $ putStrLn "Database schema is up to date."
              else liftIO $ do
                putStrLn "****************************************************"
                putStrLn "WARNING: Database schema mismatch detected!"
                when (not $ null pending) $ do
                  putStrLn "Pending SQL migrations:"
                  mapM_ (putStrLn . ("  - " ++)) pending
                when (not $ null missing) $ do
                  putStrLn "Persistent schema changes needed:"
                  forM_ missing $ \sql -> putStrLn ("  - " ++ T.unpack sql)
                putStrLn "Run 'make migrate-up' to apply changes."
                putStrLn "****************************************************"
                exitFailure
        )
        pool
      exitSuccess
    ["generate", name] -> do
      runSqlPool (generateMigration name) pool
      exitSuccess
    _ -> do
      putStrLn "Usage: migrate-exe [up|down|check|generate <name>]"
      exitFailure

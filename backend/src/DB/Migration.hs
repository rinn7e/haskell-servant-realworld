module DB.Migration (runMigrationsUp, runMigrationsDown, ensureMigrationsTable, getAppliedMigrations, getLastRanMigration, generateMigration, getPendingMigrations) where

import Control.Monad (forM_, when)
import Control.Monad.IO.Class (liftIO)
import Data.ByteString (ByteString)
import Data.ByteString qualified as BS
import Data.List (isPrefixOf, sort)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Data.Text.IO qualified as TIO
import Database.Persist (toPersistValue)
import Database.Persist.Sql (Single (..), SqlPersistT, getMigration, rawExecute, rawSql)
import System.Directory (createDirectoryIfMissing, listDirectory)
import System.FilePath (takeExtension, (</>))
import Text.Printf (printf)

import DB.Schema.Type (migrateAll)

getPendingMigrations :: SqlPersistT IO [String]
getPendingMigrations = do
  ensureMigrationsTable
  applied <- getAppliedMigrations
  files <- liftIO $ listDirectory "migration"
  let ups = sort [f | f <- files, takeExtension f == ".sql", ".up.sql" `isSuffixOf` f]
  return [f | f <- ups, read (take 3 f) `notElem` applied]

runMigrationsUp :: SqlPersistT IO ()
runMigrationsUp = do
  ensureMigrationsTable
  applied <- getAppliedMigrations
  files <- liftIO $ listDirectory "migration"
  let ups = sort [f | f <- files, takeExtension f == ".sql", ".up.sql" `isSuffixOf` f]

  forM_ ups $ \f -> do
    let version = read (take 3 f) :: Int
    when (version `notElem` applied) $ do
      liftIO $ putStrLn $ "Applying migration: " ++ f
      content <- liftIO $ BS.readFile ("migration" </> f)
      rawExecute (TE.decodeUtf8 content) []
      rawExecute "INSERT INTO schema_migrations (version) VALUES (?)" [toPersistValue version]

runMigrationsDown :: SqlPersistT IO ()
runMigrationsDown = do
  applied <- getAppliedMigrations
  case reverse applied of
    [] -> liftIO $ putStrLn "No migrations to roll back."
    (v : _) -> do
      files <- liftIO $ listDirectory "migration"
      let downFile = case [file | file <- files, take 3 file == printf "%03d" v, ".down.sql" `isSuffixOf` file] of
            (f : _) -> f
            [] -> error $ "Down migration not found for version " ++ show v
      liftIO $ putStrLn $ "Rolling back migration: " ++ downFile
      content <- liftIO $ BS.readFile ("migration" </> downFile)
      rawExecute (TE.decodeUtf8 content) []
      rawExecute "DELETE FROM schema_migrations WHERE version = ?" [toPersistValue v]

ensureMigrationsTable :: SqlPersistT IO ()
ensureMigrationsTable = do
  rawExecute "CREATE TABLE IF NOT EXISTS schema_migrations (version INTEGER PRIMARY KEY, applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP)" []

getAppliedMigrations :: SqlPersistT IO [Int]
getAppliedMigrations = do
  res <- rawSql "SELECT version FROM schema_migrations ORDER BY version ASC" []
  return $ map unSingle res

getLastRanMigration :: SqlPersistT IO (Maybe Int)
getLastRanMigration = do
  ensureMigrationsTable
  res <- rawSql "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1" []
  case res of
    (Single v : _) -> return (Just v)
    _ -> return Nothing

generateMigration :: String -> SqlPersistT IO ()
generateMigration name = do
  statements <- getMigration migrateAll
  if null statements
    then liftIO $ putStrLn "No changes detected in schema."
    else do
      liftIO $ createDirectoryIfMissing True "migration"
      files <- liftIO $ listDirectory "migration"
      let versions = [read (take 3 f) :: Int | f <- files, takeExtension f == ".sql"]
      let nextVersion = if null versions then 1 else maximum versions + 1
      let baseName = printf "%03d_%s" nextVersion name

      let upFile = "migration" </> baseName ++ ".up.sql"
      let downFile = "migration" </> baseName ++ ".down.sql"

      liftIO $ do
        putStrLn $ "Generating: " ++ upFile
        TIO.writeFile upFile (T.unlines $ map (<> ";") statements)
        putStrLn $ "Generating: " ++ downFile
        TIO.writeFile downFile "-- Write your rollback SQL here\n"
        putStrLn "Generation complete. Please review the SQL files."

isSuffixOf :: (Eq a) => [a] -> [a] -> Bool
isSuffixOf suffix list = suffix == drop (length list - length suffix) list

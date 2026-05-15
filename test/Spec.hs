{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module Main where

import Control.Monad.Logger (runNoLoggingT)
import Data.ByteString.Char8 qualified as BSC
import Data.ByteString.Lazy qualified as BSL
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Database.Persist.Postgresql (createPostgresqlPool)
import Database.Persist.Sql (runSqlPool)
import Network.Wai.Handler.Warp (withApplication)
import Servant
import Servant.Auth.Server
import Test.Hspec
import Test.Hspec.Servant

import Api
import Auth (makeSecretKey)
import DB
import Handler
import Type

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
  describe "Conduit API" $ do
    it "health check /metadata" $ do
      -- This is a unit test style, but we want integration.
      -- We'll need a mock or real DB.
      pendingWith "Integration tests require a running database"

-- Example of how to structure integration tests
-- withServantApp :: (Port -> IO ()) -> IO ()
-- withServantApp action = do
--   pool <- runNoLoggingT $ createPostgresqlPool "host=localhost dbname=realworld_test user=postgres password=postgres port=5432" 1
--   let jwtSecret = BSL.fromStrict $ TE.encodeUtf8 "test-secret-key-at-least-32-chars-long"
--   let secretKey = makeSecretKey jwtSecret
--   let jwtSettings = defaultJWTSettings secretKey
--   let env = AppEnv pool jwtSettings secretKey
--   let cfg = defaultCookieSettings :. jwtSettings :. EmptyContext
--   withApplication (return $ serveWithContext api cfg (server env)) action

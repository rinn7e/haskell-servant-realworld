module Api.OpenApi
  ( openApiSpec
  ) where

import Control.Lens ((&), (.~), (?~), (^.))
import Data.HashMap.Strict.InsOrd qualified as InsOrd
import Data.HashSet.InsOrd qualified as InsOrdHashSet
import Data.List (isPrefixOf)
import Data.Proxy (Proxy (..))
import Data.OpenApi
  ( ApiKeyLocation (..)
  , ApiKeyParams (..)
  , Referenced (..)
  , SecurityRequirement (..)
  , SecurityScheme (..)
  , SecuritySchemeType (..)
  , SecurityDefinitions (..)
  , OpenApi
  , PathItem (..)
  , Operation (..)
  , paths
  , info
  , components
  , securitySchemes
  , description
  , security
  , title
  , version
  )
import Data.Text (Text)
import Servant ((:>))
import Servant qualified as S
import Servant.Auth.Server qualified as S
import Servant.OpenApi

import DB.Schema.Type (UserId)
import Type (API)

-- | Orphan instance to seamlessly skip S.Auth during automatic OpenApi parsing.
-- This allows servant-openapi3 to process authenticated routes safely.
instance HasOpenApi sub => HasOpenApi (S.Auth auths UserId :> sub) where
  toOpenApi _ = toOpenApi (Proxy @sub)

-- | Beautifully configured OpenApi specification for the Conduit backend.
openApiSpec :: OpenApi
openApiSpec = applyTags (toOpenApi (Proxy @API))
  & info . title .~ "Conduit API"
  & info . version .~ "1.0.0"
  & info . description ?~ "RealWorld Conduit API backend using Servant, Postgres, and Esqueleto!"
  & components . securitySchemes .~ SecurityDefinitions (InsOrd.fromList [("jwt", securityScheme)])
  & security .~ [SecurityRequirement (InsOrd.fromList [("jwt", [])])]
  where
    securityScheme :: SecurityScheme
    securityScheme = SecurityScheme
      { _securitySchemeType = SecuritySchemeApiKey (ApiKeyParams "Authorization" ApiKeyHeader)
      , _securitySchemeDescription = Just "JWT Bearer token format: Token <JWT_TOKEN>"
      }

-- | Automatically tag all paths in the OpenApi spec based on their URL prefixes.
applyTags :: OpenApi -> OpenApi
applyTags spec = spec & paths .~ InsOrd.mapWithKey tagPathItem (spec ^. paths)
  where
    tagPathItem :: FilePath -> PathItem -> PathItem
    tagPathItem path pathItem
      | "/api/articles" `isPrefixOf` path    = addTag "Articles" pathItem
      | "/api/profiles" `isPrefixOf` path    = addTag "Profile" pathItem
      | "/api/tags" `isPrefixOf` path        = addTag "Tags" pathItem
      | "/api/users" `isPrefixOf` path       = addTag "Authentication" pathItem
      | "/api/user" `isPrefixOf` path        = addTag "User" pathItem
      | "/api/metadata" `isPrefixOf` path    = addTag "Metadata" pathItem
      | otherwise                            = pathItem

    addTag :: Text -> PathItem -> PathItem
    addTag t pi = pi
      { _pathItemGet    = fmap (setTag t) (_pathItemGet pi)
      , _pathItemPost   = fmap (setTag t) (_pathItemPost pi)
      , _pathItemPut    = fmap (setTag t) (_pathItemPut pi)
      , _pathItemDelete = fmap (setTag t) (_pathItemDelete pi)
      , _pathItemPatch  = fmap (setTag t) (_pathItemPatch pi)
      }

    setTag :: Text -> Operation -> Operation
    setTag t op = op { _operationTags = InsOrdHashSet.fromList [t] }

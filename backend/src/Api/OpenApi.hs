module Api.OpenApi
  ( openApiSpec
  ) where

import Control.Lens ((&), (.~), (?~))
import Data.HashMap.Strict.InsOrd qualified as InsOrd
import Data.OpenApi
  ( ApiKeyLocation (..)
  , ApiKeyParams (..)
  , OpenApi
  , SecurityDefinitions (..)
  , SecurityRequirement (..)
  , SecurityScheme (..)
  , SecuritySchemeType (..)
  , components
  , description
  , info
  , security
  , securitySchemes
  , title
  , version
  )
import Data.Proxy (Proxy (..))
import Servant ((:>))
import Servant.Auth.Server qualified as S
import Servant.OpenApi

import DB.Schema.Type (UserId)
import Type (API)

{- | Orphan instance to seamlessly skip S.Auth during automatic OpenApi parsing.
This allows servant-openapi3 to process authenticated routes safely.
-}
instance (HasOpenApi sub) => HasOpenApi (S.Auth auths UserId :> sub) where
  toOpenApi _ = toOpenApi (Proxy @sub)

-- | Beautifully configured OpenApi specification for the Conduit backend.
openApiSpec :: OpenApi
openApiSpec =
  toOpenApi (Proxy @API)
    & info . title .~ "Conduit API"
    & info . version .~ "1.0.0"
    & info . description
      ?~ "RealWorld Conduit API backend using Servant, Postgres, and Esqueleto!"
    & components . securitySchemes
      .~ SecurityDefinitions (InsOrd.fromList [("jwt", securityScheme)])
    & security .~ [SecurityRequirement (InsOrd.fromList [("jwt", [])])]
 where
  securityScheme :: SecurityScheme
  securityScheme =
    SecurityScheme
      { _securitySchemeType = SecuritySchemeApiKey (ApiKeyParams "Authorization" ApiKeyHeader)
      , _securitySchemeDescription = Just "JWT Bearer token format: Token <JWT_TOKEN>"
      }

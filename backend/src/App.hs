module App
  ( AppEnv (..)
  , server
  ) where

import Data.Proxy (Proxy (..))
import Servant (NamedRoutes)
import Servant qualified as S

import Api.Article.Handler (articlesServer)
import Api.Article.Type (ArticlesRoutes)
import Api.Auth.Handler (authServer)
import Api.Auth.Type (AuthRoutes)
import Api.Metadata.Handler (metadataServer)
import Api.Metadata.Type (MetadataRoutes)
import Api.Profile.Handler (profilesServer)
import Api.Profile.Type (ProfilesRoutes)
import Api.Tag.Handler (tagsServer)
import Api.Tag.Type (TagsRoutes)
import Api.User.Handler (userServer)
import Api.User.Type (UserRoutes)
import Common.Type.App (AppEnv (..), runApp)
import Type

server :: AppEnv -> S.Server API
server env auth =
  AppRoutes
    { metadata =
        S.hoistServer (Proxy @(NamedRoutes MetadataRoutes)) (runApp env) (metadataServer auth)
    , auth = S.hoistServer (Proxy @(NamedRoutes AuthRoutes)) (runApp env) (authServer auth)
    , user = S.hoistServer (Proxy @(NamedRoutes UserRoutes)) (runApp env) (userServer auth)
    , profiles =
        S.hoistServer (Proxy @(NamedRoutes ProfilesRoutes)) (runApp env) (profilesServer auth)
    , articles =
        S.hoistServer (Proxy @(NamedRoutes ArticlesRoutes)) (runApp env) (articlesServer auth)
    , tags = S.hoistServer (Proxy @(NamedRoutes TagsRoutes)) (runApp env) (tagsServer auth)
    }

module App
  ( AppEnv (..)
  , server
  ) where

import Data.Proxy (Proxy (..))
import Servant (NamedRoutes)
import Servant qualified as S

import Api.Article.Handler (articlesServer)
import Api.Article.Type (ArticleRoute)
import Api.Auth.Handler (authServer)
import Api.Auth.Type (AuthRoute)
import Api.Metadata.Handler (metadataServer)
import Api.Metadata.Type (MetadataRoute)
import Api.Tag.Handler (tagsServer)
import Api.Tag.Type (TagRoute)
import Api.User.Handler (userServer)
import Api.User.Type (UserRoute)
import Common.Type.App (AppEnv (..), runApp)
import Type

server :: AppEnv -> S.Server API
server env auth =
  AppRoute
    { metadata =
        S.hoistServer (Proxy @(NamedRoutes MetadataRoute)) (runApp env) (metadataServer auth)
    , auth = S.hoistServer (Proxy @(NamedRoutes AuthRoute)) (runApp env) (authServer auth)
    , user = S.hoistServer (Proxy @(NamedRoutes UserRoute)) (runApp env) (userServer auth)
    , articles =
        S.hoistServer (Proxy @(NamedRoutes ArticleRoute)) (runApp env) (articlesServer auth)
    , tags = S.hoistServer (Proxy @(NamedRoutes TagRoute)) (runApp env) (tagsServer auth)
    }

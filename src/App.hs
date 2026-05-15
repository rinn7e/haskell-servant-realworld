module App
  ( AppEnv (..)
  , server
  ) where

import Data.Proxy (Proxy (..))
import Servant (NamedRoutes)
import Servant qualified as S

import Api.Route.Articles (ArticlesRoutes, articlesServer)
import Api.Route.Metadata (MetadataRoutes, metadataServer)
import Api.Route.Profiles (ProfilesRoutes, profilesServer)
import Api.Route.Tags (TagsRoutes, tagsServer)
import Api.Route.User (UserRoutes, userServer)
import Api.Route.Users (UsersRoutes, usersServer)
import Common.Type.App (AppEnv (..), runApp)
import Type

server :: AppEnv -> S.Server API
server env auth =
  AppRoutes
    { metadata = S.hoistServer (Proxy @(NamedRoutes MetadataRoutes)) (runApp env) (metadataServer auth)
    , users = S.hoistServer (Proxy @(NamedRoutes UsersRoutes)) (runApp env) (usersServer auth)
    , user = S.hoistServer (Proxy @(NamedRoutes UserRoutes)) (runApp env) (userServer auth)
    , profiles = S.hoistServer (Proxy @(NamedRoutes ProfilesRoutes)) (runApp env) (profilesServer auth)
    , articles = S.hoistServer (Proxy @(NamedRoutes ArticlesRoutes)) (runApp env) (articlesServer auth)
    , tags = S.hoistServer (Proxy @(NamedRoutes TagsRoutes)) (runApp env) (tagsServer auth)
    }

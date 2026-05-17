module RunServer
  ( AppEnv (..)
  , runServer
  , runServerWithOpenApi
  , APIWithOpenApi
  ) where

import Data.Proxy (Proxy (..))
import Servant (NamedRoutes, (:<|>) (..))
import Servant qualified as S
import Servant.Swagger.UI qualified as SUI

import Api.Article.Handler (articleRoute)
import Api.Article.Type (ArticleRoute)
import Api.Auth.Handler (authRoute)
import Api.Auth.Type (AuthRoute)
import Api.Metadata.Handler (metadataRoute)
import Api.Metadata.Type (MetadataRoute)
import Api.OpenApi (openApiSpec)
import Api.Tag.Handler (tagRoute)
import Api.Tag.Type (TagRoute)
import Api.User.Handler (userRoute)
import Api.User.Type (UserRoute)
import Common.Type.App (AppEnv (..), runApp)
import Type

runServer :: AppEnv -> S.Server API
runServer env auth =
  AppRoute
    { metadata =
        S.hoistServer (Proxy @(NamedRoutes MetadataRoute)) (runApp env) (metadataRoute auth)
    , auth = S.hoistServer (Proxy @(NamedRoutes AuthRoute)) (runApp env) (authRoute auth)
    , user = S.hoistServer (Proxy @(NamedRoutes UserRoute)) (runApp env) (userRoute auth)
    , articles =
        S.hoistServer (Proxy @(NamedRoutes ArticleRoute)) (runApp env) (articleRoute auth)
    , tags = S.hoistServer (Proxy @(NamedRoutes TagRoute)) (runApp env) (tagRoute auth)
    }

runServerWithOpenApi :: AppEnv -> S.Server APIWithOpenApi
runServerWithOpenApi env = runServer env :<|> SUI.swaggerSchemaUIServer openApiSpec

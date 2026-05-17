module RunServer
  ( AppEnv (..)
  , runServer
  , runAdminServer
  , runFullServer
  , APIWithOpenApi
  , AdminAPIWithOpenApi
  , FullAPI
  ) where

import Data.Proxy (Proxy (..))
import Servant (NamedRoutes, (:<|>) (..))
import Servant qualified as S
import Servant.Swagger.UI qualified as SUI

import Api.Article.Admin.Handler (adminArticleRoute)
import Api.Article.Admin.Type (AdminArticleRoute)
import Api.Article.Web.Handler (articleRoute)
import Api.Article.Web.Type (ArticleRoute)
import Api.Auth.Handler (authRoute)
import Api.Auth.Type (AuthRoute)
import Api.Comment.Admin.Handler (adminCommentRoute)
import Api.Comment.Admin.Type (AdminCommentRoute)
import Api.Metadata.Admin.Handler (adminMetadataRoute)
import Api.Metadata.Admin.Type (AdminMetadataRoute)
import Api.Metadata.Web.Handler (metadataRoute)
import Api.Metadata.Web.Type (MetadataRoute)
import Api.OpenApi (adminOpenApiSpec, openApiSpec)
import Api.Tag.Handler (tagRoute)
import Api.Tag.Type (TagRoute)
import Api.User.Admin.Handler (adminUserRoute)
import Api.User.Admin.Type (AdminUserRoute)
import Api.User.Web.Handler (userRoute)
import Api.User.Web.Type (UserRoute)
import Common.Type.App (AppEnv (..), runApp)
import Type

type FullAPI = APIWithOpenApi :<|> AdminAPIWithOpenApi

runServer :: AppEnv -> S.Server WebAPI
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

runAdminServer :: AppEnv -> S.Server AdminAPI
runAdminServer env auth =
  AdminRoute
    { metadata =
        S.hoistServer (Proxy @(NamedRoutes AdminMetadataRoute)) (runApp env) (adminMetadataRoute auth)
    , articles =
        S.hoistServer (Proxy @(NamedRoutes AdminArticleRoute)) (runApp env) (adminArticleRoute auth)
    , users =
        S.hoistServer (Proxy @(NamedRoutes AdminUserRoute)) (runApp env) (adminUserRoute auth)
    , comments =
        S.hoistServer (Proxy @(NamedRoutes AdminCommentRoute)) (runApp env) (adminCommentRoute auth)
    }

runFullServer :: AppEnv -> S.Server FullAPI
runFullServer env =
  (runServer env :<|> SUI.swaggerSchemaUIServer openApiSpec)
    :<|> (runAdminServer env :<|> SUI.swaggerSchemaUIServer adminOpenApiSpec)

module Type
  ( WebAPI
  , AdminAPI
  , AppApi
  , AppRoute (..)
  , AdminRoute (..)
  , APIWithOpenApi
  , AdminAPIWithOpenApi
  ) where

import GHC.Generics (Generic)
import Servant (GenericMode (type (:-)), NamedRoutes, (:<|>), (:>))
import Servant qualified as S
import Servant.Auth.Server qualified as S
import Servant.Swagger.UI (SwaggerSchemaUI)

import Api.Article.Admin.Type (AdminArticleRoute)
import Api.Article.Web.Type (ArticleRoute)
import Api.Auth.Type (AuthRoute)
import Api.Comment.Admin.Type (AdminCommentRoute)
import Api.Metadata.Admin.Type (AdminMetadataRoute)
import Api.Metadata.Web.Type (MetadataRoute)
import Api.Tag.Type (TagRoute)
import Api.User.Admin.Type (AdminUserRoute)
import Api.User.Web.Type (UserRoute)
import DB.Schema.Type (UserId)

type AppApi auths = S.Auth auths UserId :> NamedRoutes AppRoute

data AppRoute mode = AppRoute
  { metadata :: mode :- NamedRoutes MetadataRoute
  , auth :: mode :- NamedRoutes AuthRoute
  , user :: mode :- NamedRoutes UserRoute
  , articles :: mode :- NamedRoutes ArticleRoute
  , tags :: mode :- NamedRoutes TagRoute
  }
  deriving stock (Generic)

type WebAPI = "api" :> AppApi '[S.JWT]

data AdminRoute mode = AdminRoute
  { metadata :: mode :- NamedRoutes AdminMetadataRoute
  , articles :: mode :- NamedRoutes AdminArticleRoute
  , users :: mode :- NamedRoutes AdminUserRoute
  , comments :: mode :- NamedRoutes AdminCommentRoute
  }
  deriving stock (Generic)

type AdminAPI = "api" :> "admin" :> S.Auth '[S.JWT] UserId :> NamedRoutes AdminRoute

type APIWithOpenApi = WebAPI :<|> SwaggerSchemaUI "swagger-ui" "swagger.json"

type AdminAPIWithOpenApi = AdminAPI :<|> SwaggerSchemaUI "admin/swagger-ui" "admin-swagger.json"

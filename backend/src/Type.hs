module Type
  ( API
  , AppApi
  , AppRoutes (..)
  ) where

import GHC.Generics (Generic)
import Servant (GenericMode (type (:-)), NamedRoutes, (:>))
import Servant qualified as S
import Servant.Auth.Server qualified as S

import Api.Article.Type (ArticleRoute)
import Api.Auth.Type (AuthRoute)
import Api.Metadata.Type (MetadataRoute)
import Api.Tag.Type (TagRoute)
import Api.User.Type (UserRoute)
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

type API = "api" :> AppApi '[S.JWT]

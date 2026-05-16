module Type
  ( API
  , AppApi
  , AppRoutes (..)
  ) where

import GHC.Generics (Generic)
import Servant (GenericMode (type (:-)), NamedRoutes, (:>))
import Servant qualified as S
import Servant.Auth.Server qualified as S

import Api.Article.Type (ArticlesRoutes)
import Api.Auth.Type (AuthRoutes)
import Api.Metadata.Type (MetadataRoutes)
import Api.Tag.Type (TagsRoutes)
import Api.User.Type (UserRoutes)
import DB.Schema.Type (UserId)

type AppApi auths = S.Auth auths UserId :> NamedRoutes AppRoutes

data AppRoutes mode = AppRoutes
  { metadata :: mode :- NamedRoutes MetadataRoutes
  , auth :: mode :- NamedRoutes AuthRoutes
  , user :: mode :- NamedRoutes UserRoutes
  , articles :: mode :- NamedRoutes ArticlesRoutes
  , tags :: mode :- NamedRoutes TagsRoutes
  }
  deriving stock (Generic)

type API = "api" :> AppApi '[S.JWT]

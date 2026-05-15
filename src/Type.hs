module Type
  ( API
  , AppApi
  , AppRoutes (..)
  ) where

import GHC.Generics (Generic)
import Servant (GenericMode (type (:-)), NamedRoutes, (:>))
import Servant qualified as S
import Servant.Auth.Server qualified as S

import Api.Route.Articles (ArticlesRoutes)
import Api.Route.Metadata (MetadataRoutes)
import Api.Route.Profiles (ProfilesRoutes)
import Api.Route.Tags (TagsRoutes)
import Api.Route.User (UserRoutes)
import Api.Route.Users (UsersRoutes)
import DB.Schema.Type (UserId)

type AppApi auths = S.Auth auths UserId :> NamedRoutes AppRoutes

data AppRoutes mode = AppRoutes
  { metadata :: mode :- "metadata" :> NamedRoutes MetadataRoutes
  , users :: mode :- "users" :> NamedRoutes UsersRoutes
  , user :: mode :- "user" :> NamedRoutes UserRoutes
  , profiles :: mode :- "profiles" :> NamedRoutes ProfilesRoutes
  , articles :: mode :- "articles" :> NamedRoutes ArticlesRoutes
  , tags :: mode :- "tags" :> NamedRoutes TagsRoutes
  }
  deriving stock (Generic)

type API = "api" :> AppApi '[S.JWT]

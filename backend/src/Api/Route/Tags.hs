module Api.Route.Tags where

import Database.Persist.Sql (runSqlPool)
import Effectful (liftIO)
import Effectful.Error.Static (throwError)
import Effectful.Reader.Static (ask)
import GHC.Generics (Generic)
import Servant (GenericMode (type (:-)), Get, JSON, NamedRoutes, (:>))
import Servant qualified as S
import Servant.Auth.Server qualified as S

import Entity.Tag.Api (TagListResponse (..))
import Common.Type.App (App, AppEnv (..))
import DB.Schema.Type (UserId)
import Entity.Tag.Query (getTags)
import DB.Util (runDB)

data TagsRoutes mode = TagsRoutes
  { tags :: mode :- Get '[JSON] TagListResponse
  -- ^ GET /api/tags
  }
  deriving stock (Generic)

tagsServer :: S.AuthResult UserId -> S.ServerT (NamedRoutes TagsRoutes) App
tagsServer _auth =
  TagsRoutes
    { tags = getTagsHandler
    }

getTagsHandler :: App TagListResponse
getTagsHandler = do
  tags <- runDB getTags
  return $ TagListResponse tags

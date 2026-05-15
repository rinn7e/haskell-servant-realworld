module Api.Route.Tags where

import Database.Persist.Sql (runSqlPool)
import Effectful (liftIO)
import Effectful.Error.Static (throwError)
import Effectful.Reader.Static (ask)
import GHC.Generics (Generic)
import Servant (GenericMode (type (:-)), Get, JSON, NamedRoutes, (:>))
import Servant qualified as S
import Servant.Auth.Server qualified as S

import Api.Type (TagsResponse (..))
import Common.Type.App (App, AppEnv (..))
import DB.Tag.Query (getTags)
import DB.Schema.Type (UserId)
import DB.Util (runDB)

data TagsRoutes mode = TagsRoutes
  { tags :: mode :- Get '[JSON] TagsResponse
  -- ^ GET /api/tags
  }
  deriving stock (Generic)

tagsServer :: S.AuthResult UserId -> S.ServerT (NamedRoutes TagsRoutes) App
tagsServer _auth =
  TagsRoutes
    { tags = getTagsHandler
    }

getTagsHandler :: App TagsResponse
getTagsHandler = do
  tags <- runDB getTags
  return $ TagsResponse tags

module Api.Tag.Handler where

import Servant (NamedRoutes)
import Servant qualified as S
import Servant.Auth.Server qualified as S

import Api.Tag.Type
import Common.Type.App (App)
import DB.Schema.Type (UserId)
import DB.Util (runDB)
import Entity.Tag.Api (TagListResponse (..))
import Entity.Tag.Query (getTags)

tagRoute :: S.AuthResult UserId -> S.ServerT (NamedRoutes TagRoute) App
tagRoute _auth =
  TagRoute
    { getTagList = getTagListHandler
    }

getTagListHandler :: App TagListResponse
getTagListHandler = do
  tags <- runDB getTags
  return $ TagListResponse tags

module Api.User.Admin.Type where

import Data.Aeson (FromJSON (..), ToJSON (..))
import Data.Text (Text)
import GHC.Generics (Generic)
import Servant
  ( Capture
  , Delete
  , Description
  , GenericMode (type (:-))
  , Get
  , JSON
  , Put
  , QueryParam
  , ReqBody
  , Summary
  , (:>)
  )
import Servant qualified as S

import Api.TagCombinator (Tag)
import Data.OpenApi (ToSchema (..))

data UpdateUserRoleRequest = UpdateUserRoleRequest
  { role :: Text
  }
  deriving stock (Show, Generic)
  deriving anyclass (FromJSON, ToJSON, ToSchema)

data AdminUserResponse = AdminUserResponse
  { id :: Int
  , username :: Text
  , email :: Text
  , bio :: Maybe Text
  , image :: Maybe Text
  , role :: Text
  }
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, ToSchema)

data AdminUserListResponse = AdminUserListResponse
  { users :: [AdminUserResponse]
  , totalCount :: Int
  }
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, ToSchema)

data AdminUserRoute mode = AdminUserRoute
  { getUsers
      :: mode
        :- "users"
          :> Summary "Get All Users"
          :> Description "Retrieve all registered users with pagination"
          :> Tag "Admin Users"
          :> QueryParam "page" Int
          :> Get '[JSON] AdminUserListResponse
  , updateUserRole
      :: mode
        :- "users"
          :> Capture "id" Int
          :> "role"
          :> Summary "Update User Role"
          :> Description "Promote a user to Admin or demote to User"
          :> Tag "Admin Users"
          :> ReqBody '[JSON] UpdateUserRoleRequest
          :> Put '[JSON] AdminUserResponse
  , deleteUser
      :: mode
        :- "users"
          :> Capture "id" Int
          :> Summary "Ban User"
          :> Description "Permanently delete/ban a user from the platform"
          :> Tag "Admin Users"
          :> Delete '[JSON] S.NoContent
  }
  deriving stock (Generic)

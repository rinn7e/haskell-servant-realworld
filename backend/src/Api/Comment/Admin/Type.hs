module Api.Comment.Admin.Type where

import Data.Aeson (ToJSON)
import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics (Generic)
import Servant
  ( Capture
  , Delete
  , Description
  , GenericMode (type (:-))
  , Get
  , JSON
  , QueryParam
  , Summary
  , (:>)
  )
import Servant qualified as S

import Api.TagCombinator (Tag)
import Data.OpenApi (ToSchema (..))

data AdminCommentResponse = AdminCommentResponse
  { id :: Int
  , body :: Text
  , createdAt :: UTCTime
  , articleSlug :: Text
  , authorUsername :: Text
  }
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, ToSchema)

data AdminCommentListResponse = AdminCommentListResponse
  { comments :: [AdminCommentResponse]
  , totalCount :: Int
  }
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, ToSchema)

data AdminCommentRoute mode = AdminCommentRoute
  { getComments
      :: mode
        :- "comments"
          :> Summary "Get All Comments"
          :> Description "Retrieve all comments in the system for administrative moderation"
          :> Tag "Admin Comments"
          :> QueryParam "page" Int
          :> Get '[JSON] AdminCommentListResponse
  , deleteComment
      :: mode
        :- "comments"
          :> Capture "id" Int
          :> Summary "Delete Comment"
          :> Description "Administrative deletion of an offensive comment globally"
          :> Tag "Admin Comments"
          :> Delete '[JSON] S.NoContent
  }
  deriving stock (Generic)

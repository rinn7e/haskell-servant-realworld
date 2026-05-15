module Common.Util.Auth where

import Control.Lens
import Control.Monad.Except (ExceptT, runExceptT, throwError)
import Control.Monad.IO.Class (liftIO)
import Crypto.JOSE.JWS (Alg)
import Crypto.JWT (ClaimsSet, Error, JWK, JWS, JWSHeader, NumericDate (..), StringOrURI, bestJWSAlg, claimExp, claimIat, claimSub, emptyClaimsSet, encodeCompact, fromOctets, newJWSHeader, signClaims)
import Crypto.Random.Entropy qualified as Entropy
import Crypto.Random.Types (MonadRandom (..))
import Data.Aeson (FromJSON, ToJSON, toJSON)
import Data.Aeson qualified as A
import Data.ByteString.Lazy qualified as BS
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Data.Time (addUTCTime, getCurrentTime)
import Database.Persist.Sql (fromSqlKey)
import Servant.Auth.Server

import DB.Schema.Type (UserId)

-- In jose 0.11, signClaims needs MonadRandom and AsError.
-- If IO doesn't have MonadRandom instance from crypton, we provide it for our stack.
instance MonadRandom (ExceptT Error IO) where
  getRandomBytes = liftIO . Entropy.getEntropy

makeSecretKey :: BS.ByteString -> JWK
makeSecretKey = fromOctets

generateToken :: JWK -> UserId -> IO Text
generateToken key userId = do
  now <- getCurrentTime
  let subText = T.pack (show (fromSqlKey userId))
  let mSub = A.fromJSON (A.String subText) :: A.Result StringOrURI
  let claims = case mSub of
        A.Success sub ->
          emptyClaimsSet
            & claimSub ?~ sub
            & claimIat ?~ NumericDate now
            & claimExp ?~ NumericDate (addUTCTime (3600 * 24 * 7) now) -- 7 days
        _ -> emptyClaimsSet

  -- Use runExceptT to handle JWT errors
  res <- runExceptT $ do
    alg <- bestJWSAlg key :: ExceptT Error IO Alg
    signClaims key (newJWSHeader ((), alg)) claims

  case res of
    Left (_ :: Error) -> return ""
    Right jwt -> return . TE.decodeUtf8 . BS.toStrict . encodeCompact $ jwt

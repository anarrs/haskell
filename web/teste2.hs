{-# LANGUAGE OverloadedStrings, TypeFamilies, QuasiQuotes,
             TemplateHaskell, GADTs, FlexibleInstances,
             MultiParamTypeClasses, DeriveDataTypeable,
             GeneralizedNewtypeDeriving, ViewPatterns, EmptyDataDecls #-}
import Yesod
import Database.Persist.Postgresql
import Data.Text
import Control.Monad.Logger (runStdoutLoggingT)

data Pagina = Pagina{connPool :: ConnectionPool}

instance Yesod Pagina
share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
Clientes json
   nome Text
   deriving Show
|]

mkYesod "Pagina" [parseRoutes|
/ HomeR GET 
/cadastro UserR GET POST
/cadastro/check/#ClientesId CheckR GET
/cadastro/update/#ClientesId UpdateR PUT
|]

instance YesodPersist Pagina where
   type YesodPersistBackend Pagina = SqlBackend
   runDB f = do
       master <- getYesod
       let pool = connPool master
       runSqlPool f pool
------------------------------------------------------

getHomeR :: Handler Html
getHomeR = defaultLayout $ [whamlet| 
    <h1> Ola Mundo
|] 

getUserR :: Handler ()
getUserR = do
    allClientes <- runDB $ selectList [] [Asc ClientesNome]
    sendResponse (object [pack "data" .= fmap toJSON allClientes])
    
postUserR :: Handler ()
postUserR = do
    clientes <- requireJsonBody :: Handler Clientes
    runDB $ insert clientes
    sendResponse (object [pack "resp" .= pack "CREATED"])

getCheckR :: ClientesId -> Handler ()
getCheckR pid = do
    cli <- runDB $ get404 pid
    sendResponse $ toJSON cli

putUpdateR :: ClientesId -> Handler ()
putUpdateR pid = do
    cli <- requireJsonBody :: Handler Clientes
    runDB $ update pid [ClientesNome =. clientesNome cli]
    sendResponse (object [pack "resp" .= pack "UPDATED"])


connStr = "dbname=d1c1ae91hmds69 host=ec2-23-21-165-183.compute-1.amazonaws.com user=cxdimwokdlztok password=WqgSJY8rsR7Q7nTfX1NzbV2K32 port=5432"

main::IO()
main = runStdoutLoggingT $ withPostgresqlPool connStr 10 $ \pool -> liftIO $ do 
       runSqlPersistMPool (runMigration migrateAll) pool
       warp 8080 (Pagina pool)

{-
criar uma tabela produto com os campos nome (text) e valor (double).
e criar a rota /prod com GET para o form e POST para a inserção
-}
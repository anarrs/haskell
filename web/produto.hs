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
{-
share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
Produtos json
   nome Text
   valor Double
   deriving Show
|]-}

mkYesod "Pagina" [parseRoutes|
/ HomeR GET 
--/cadastro CadR GET POST
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
{-
getCadR :: Handler Html
getCadR = defaultLayout $ do
  addScriptRemote "https://ajax.googleapis.com/ajax/libs/jquery/1.12.0/jquery.min.js"
  [whamlet| 
    <form>
        Nome: <input type="text" id="nome"><br>
        Valor: <input type="text" id="valor">
    <button #btn> OK
  |]  
  toWidget [julius|
     $(main);
     function main(){
         $("#btn").click(function(){
             $.ajax({
                 contentType: "application/json",
                 url: "@{CadR}",
                 type: "POST",
                 data: JSON.stringify({"nome":$("#nome").val(),"valor":$("#valor").val()}),
                 success: function(data) {
                     alert(data.resp);
                     $("#nome").val("");
                     $("#valor").val("");
                 }
            })
         });
     }
  |]

postCadR :: Handler ()
postCadR = do
    produtos <- requireJsonBody :: Handler Produtos
    runDB $ insert produtos
    sendResponse (object [pack "resp" .= pack "CREATED"])
-}

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
--bd garcia:
--connStr = "dbname=dd9en8l5q4hh2a host=ec2-107-21-219-201.compute-1.amazonaws.com user=kpuwtbqndoeyqb password=aCROh525uugAWF1l7kahlNN3E0 port=5432"

main::IO()
main = runStdoutLoggingT $ withPostgresqlPool connStr 10 $ \pool -> liftIO $ do 
       runSqlPersistMPool (runMigration migrateAll) pool
       warp 8080 (Pagina pool)

{-
criar uma tabela produto com os campos nome (text) e valor (double).
e criar a rota /prod com GET para o form e POST para a inserção
-}
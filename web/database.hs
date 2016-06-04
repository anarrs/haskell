{-

postgres.heroku.com
postgres.heroku.com/databases

1) cria a tabeça Clientes com os campos id e nome;

2) cria o tipo mp haskell
data Clientes = Clientes {nomeClientes :: Text}
    deriving Show
    
3) A palavra json faz com que ele leia jsons de forma {nome: "Joao"}

-}
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
|]

instance YesodPersist Pagina where
   type YesodPersistBackend Pagina = SqlBackend
   runDB f = do
       master <- getYesod
       let pool = connPool master
       runSqlPool f pool
------------------------------------------------------

getUserR :: Handler Html
getUserR = defaultLayout $ do
  addScriptRemote "https://ajax.googleapis.com/ajax/libs/jquery/1.12.0/jquery.min.js"
  [whamlet| 
    <form>
        Nome: <input type="text" id="usuario">
    <button #btn> OK
  |]  
  toWidget [julius|
     $(main);
     function main(){
         $("#btn").click(function(){
             $.ajax({
                 contentType: "application/json",
                 url: "@{UserR}",
                 type: "POST",
                 data: JSON.stringify({"nome":$("#usuario").val()}),
                 success: function(data) {
                     alert(data.resp);
                     $("#usuario").val("");
                 }
            })
         });
     }
  |]

postUserR :: Handler ()
postUserR = do
    clientes <- requireJsonBody :: Handler Clientes
    runDB $ insert clientes
    sendResponse (object [pack "resp" .= pack "CREATED"])
    -- Linha 60: Le o json {nome:"Teste"} e converte para
    -- Cliente "Teste". O comando runDB $ insert (Clientes "Teste")
    -- {resp:"CREATED"}
getHomeR :: Handler Html
getHomeR = defaultLayout $ [whamlet| 
    <h1> Ola Mundo
|] 

connStr = "dbname=dd9en8l5q4hh2a host=ec2-107-21-219-201.compute-1.amazonaws.com user=kpuwtbqndoeyqb password=aCROh525uugAWF1l7kahlNN3E0 port=5432"

main::IO()
main = runStdoutLoggingT $ withPostgresqlPool connStr 10 $ \pool -> liftIO $ do 
       runSqlPersistMPool (runMigration migrateAll) pool
       warp 8080 (Pagina pool)


{-
criar uma tabela produto com os campos nome (text) e valor (double).
e criar a rota /prod com GET para o form e POST para a inserção
-}
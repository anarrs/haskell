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

Produto json
   nome Text
   valor Double
   deriving Show
   
ClientesProduto json
   clid ClientesId
   prid ProdutoId
   UniqueClientesProduto clid prid
|]

mkYesod "Pagina" [parseRoutes|
/cadastro UserR GET POST
/cadastro/action/#ClientesId ActionR GET PUT DELETE
/produto ProdutoR GET POST
/venda VendaR POST
|]

instance YesodPersist Pagina where
   type YesodPersistBackend Pagina = SqlBackend
   runDB f = do
       master <- getYesod
       let pool = connPool master
       runSqlPool f pool
------------------------------------------------------
getUserR :: Handler ()
getUserR = do
    allClientes <- runDB $ selectList [] [Asc ClientesNome]
    sendResponse (object [pack "data" .= fmap toJSON allClientes])
    
postUserR :: Handler ()
postUserR = do
    clientes <- requireJsonBody :: Handler Clientes
    runDB $ insert clientes
    sendResponse (object [pack "resp" .= pack "CREATED"])

getProdutoR :: Handler ()
getProdutoR = do
    allProd <- runDB $ selectList [] [Asc ProdutoValor]
    sendResponse (object [pack "data" .= fmap toJSON allProd])
    
postProdutoR :: Handler ()
postProdutoR = do
    prod <- requireJsonBody :: Handler Produto
    runDB $ insert prod
    sendResponse (object [pack "resp" .= pack "CREATED"])

postVendaR :: Handler ()
postVendaR = do
    venda <- requireJsonBody :: Handler ClientesProduto
    runDB $ insert venda
    sendResponse (object [pack "resp" .= pack "CREATED"])
    
getActionR :: ClientesId -> Handler ()
getActionR pid = do
    cli <- runDB $ get404 pid
    sendResponse $ toJSON cli

deleteActionR :: ClientesId -> Handler ()
deleteActionR pid = do
    runDB $ delete pid
    sendResponse (object [pack "resp" .= pack "DELETED"])
    
putActionR :: ClientesId -> Handler ()
putActionR pid = do
    cli <- requireJsonBody :: Handler Clientes
    runDB $ update pid [ClientesNome =. clientesNome cli]
    sendResponse (object [pack "resp" .= pack "UPDATED"])

connStr = "dbname=d1c1ae91hmds69 host=ec2-23-21-165-183.compute-1.amazonaws.com user=cxdimwokdlztok password=WqgSJY8rsR7Q7nTfX1NzbV2K32 port=5432"

main::IO()
main = runStdoutLoggingT $ withPostgresqlPool connStr 10 $ \pool -> liftIO $ do 
       runSqlPersistMPool (runMigration migrateAll) pool
       warp 8080 (Pagina pool)



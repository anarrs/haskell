{-# LANGUAGE OverloadedStrings, TypeFamilies, QuasiQuotes,
             TemplateHaskell, GADTs, FlexibleContexts,
             MultiParamTypeClasses, DeriveDataTypeable,
             GeneralizedNewtypeDeriving, ViewPatterns #-}
module Foundation where
import Import
import Yesod
import Yesod.Static
import Data.Text
import Database.Persist.Postgresql
    ( ConnectionPool, SqlBackend, runSqlPool, runMigration )

data Sitio = Sitio {getStatic :: Static, connPool :: ConnectionPool }

share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
Departamento
   nome Text
   sigla Text sqltype=varchar(3)
   deriving Show

Pessoa
   nome Text
   idade Int
   salario Double
   deptoid DepartamentoId
   deriving Show
   
Noticia
   titulo Text sqltype=varchar(200)
   corpo Text
   autor Text sqltype=varchar(100)
   cd_tipo_materia Int
   deriving Show

|]

staticFiles "static"

mkYesodData "Sitio" pRoutes

mkMessage "Sitio" "messages" "pt-br"

instance YesodPersist Sitio where
   type YesodPersistBackend Sitio = SqlBackend
   runDB f = do
       master <- getYesod
       let pool = connPool master
       runSqlPool f pool

instance Yesod Sitio where

type Form a = Html -> MForm Handler (FormResult a, Widget)

instance RenderMessage Sitio FormMessage where
    renderMessage _ _ = defaultFormMessage
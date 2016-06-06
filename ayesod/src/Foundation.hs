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
Usuario
    nome Text
    UniqueUsuario nome
    senha Text
    deriving Show
    
Noticia
   titulo Text sqltype=varchar(200)
   corpo Textarea
   autor Text sqltype=varchar(100)
   idtipo TipoId default=1
   deriving Show
    
Imagem
   url Text sqltype=varchar(200)
   legenda Text
   autor Text sqltype=varchar(100)
   idnoticia NoticiaId
   deriving Show

Tipo
   nome Text
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
    authRoute _ = Just $ LoginR
    isAuthorized LoginR _ = return Authorized
    isAuthorized CadastroNoticiaR _ = isUser
    isAuthorized CadastroImagemR _ = isUser
    isAuthorized CadastroTipoR _ = isUser
    isAuthorized CadastroUsuarioR _ = isUser
    isAuthorized ListaNoticiasR _ = isUser
    isAuthorized ListaImagensR _ = isUser
    isAuthorized ListaUsuariosR _ = isUser
    isAuthorized _ _ = return Authorized
    

isUser = do
    mu <- lookupSession "_ID"
    return $ case mu of
        Nothing -> AuthenticationRequired
        Just _ -> Authorized

type Form a = Html -> MForm Handler (FormResult a, Widget)

instance RenderMessage Sitio FormMessage where
    renderMessage _ _ = defaultFormMessage
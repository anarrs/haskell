{-# LANGUAGE OverloadedStrings, QuasiQuotes,
             TemplateHaskell #-}
 
module Handlers where
import Import
import Yesod
import Foundation
import Control.Monad.Logger (runStdoutLoggingT)
import Control.Applicative
import Data.Text
import Text.Lucius (CssUrl, luciusFile, luciusFileReload, renderCss)

import Database.Persist.Postgresql

mkYesodDispatch "Sitio" pRoutes


widgetCss :: Widget
widgetCss = do
    addStylesheet $ StaticR css_bootstrap_css
    addStylesheet $ StaticR css_carousel_customizado_css
    addStylesheet $ StaticR css_sticky_footer_navbar_css

widgetScript :: Widget
widgetScript = do
    addScriptRemote "https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"
    addScript $ StaticR js_bootstrap_min_js
    addScript $ StaticR js_validator_min_js

formCadastroNoticia :: Form Noticia
formCadastroNoticia = renderDivs $ Noticia <$>
                      areq textField "Titulo" Nothing <*>
                      areq textareaField "Corpo" Nothing <*>
                      areq textField "Autor" Nothing <*>
                      areq intField "Tipo" Nothing

formCadastroImagem :: Form Imagem
formCadastroImagem = renderDivs $ Imagem <$>
                      areq textField "Url" Nothing <*>
                      areq textField "Legenda" Nothing <*>
                      areq textField "Autor" Nothing <*>
                      areq (selectField nots) "Noticia" Nothing

nots = do
       entidades <- runDB $ selectList [] [Asc NoticiaTitulo] 
       optionsPairs $ fmap (\ent -> (noticiaTitulo $ entityVal ent, entityKey ent)) entidades

formUsuario :: Form Usuario
formUsuario = renderDivs $ Usuario <$>
             areq textField "Nome" Nothing <*>
             areq passwordField "Senha" Nothing


getLogoutR :: Handler Html
getLogoutR = do
    deleteSession "_ID"
    redirect HomeR

getLoginR :: Handler Html
getLoginR = do
    (widget, enctype) <- generateFormPost formUsuario
    defaultLayout $ widgetCss >> 
     $(whamletFile "templates/menu.hamlet") >> 
     $(whamletFile "templates/footer.hamlet") >> 
     widgetLogin LoginR enctype widget "Usuarios"

postLoginR :: Handler Html
postLoginR = do
    ((result,_),_) <- runFormPost formUsuario
    case result of
        FormSuccess usr -> do
            usuario <- runDB $ selectFirst [UsuarioNome ==. usuarioNome usr, UsuarioSenha ==. usuarioSenha usr ] []
            case usuario of
                Just (Entity uid usr) -> do
                    setSession "_ID" (usuarioNome usr)
                    redirect CadastroNoticiaR
                Nothing -> do
                    setMessage $ [shamlet| <p class="text-center"> Usuário inválido |]
                    redirect LoginR
        _ -> redirect LoginR


getHomeR :: Handler Html
getHomeR = do
           defaultLayout $ widgetCss >> 
               $(whamletFile "templates/menu.hamlet") >> 
               $(whamletFile "hamlet/destaque.hamlet") >> 
               $(whamletFile "hamlet/noticias_boletim.hamlet") >> 
               $(whamletFile "templates/footer.hamlet") >> 
               widgetScript


getNoticiasR :: Handler Html
getNoticiasR = do
               listaN <- runDB $ selectList [] [Desc NoticiaId]
               defaultLayout $ widgetCss >> 
                   $(whamletFile "templates/menu.hamlet") >> 
                   $(whamletFile "hamlet/noticias.hamlet") >> 
                   $(whamletFile "templates/footer.hamlet") >> 
                   widgetScript

getNoticiaR :: NoticiaId -> Handler Html
getNoticiaR nid = do
             noticia <- runDB $ get404 nid 
             listaI <- runDB $ selectList [ImagemIdnoticia ==. nid ] []
             defaultLayout $ widgetCss >> 
                 $(whamletFile "templates/menu.hamlet") >> 
                 $(whamletFile "hamlet/noticia.hamlet") >> 
                 $(whamletFile "templates/footer.hamlet") >> 
                 widgetScript


-- FUNCAO PARA GERAR FORMULARIOS DE UMA MANEIRA GENERICA
widgetForm :: Route Sitio -> Enctype -> Widget -> Text -> Widget
widgetForm x enctype widget y = $(whamletFile "templates/form.hamlet")

-- FUNCAO PARA GERAR FORMULARIOS DE LOGIN
widgetLogin :: Route Sitio -> Enctype -> Widget -> Text -> Widget
widgetLogin x enctype widget y = $(whamletFile "templates/login.hamlet")

getCadastroNoticiaR :: Handler Html
getCadastroNoticiaR = do
             (widget, enctype) <- generateFormPost formCadastroNoticia
             defaultLayout $ widgetCss >> 
                 $(whamletFile "templates/menulogado.hamlet") >> 
                 $(whamletFile "templates/footer.hamlet") >> 
                 widgetForm CadastroNoticiaR enctype widget "Noticia"
                 

postCadastroNoticiaR :: Handler Html
postCadastroNoticiaR = do
                ((result, _), _) <- runFormPost formCadastroNoticia
                case result of
                    FormSuccess noticia -> do
                       runDB $ insert noticia 
                       defaultLayout [whamlet| 
                           <h1>Noticia inserida com sucesso. 
                       |]
                    _ -> redirect CadastroNoticiaR



getCadastroImagemR :: Handler Html
getCadastroImagemR = do
             (widget, enctype) <- generateFormPost formCadastroImagem
             defaultLayout $ widgetCss >> 
                 $(whamletFile "templates/menulogado.hamlet") >> 
                 $(whamletFile "templates/footer.hamlet") >> 
                 widgetForm CadastroImagemR enctype widget "Imagem"
                 

postCadastroImagemR :: Handler Html
postCadastroImagemR = do
                ((result, _), _) <- runFormPost formCadastroImagem
                case result of
                    FormSuccess imagem -> do
                       runDB $ insert imagem 
                       defaultLayout [whamlet| 
                           <h1>Imagem inserida com sucesso. 
                       |]
                    _ -> redirect CadastroImagemR

getCadastroUsuarioR :: Handler Html
getCadastroUsuarioR = do
             (widget, enctype) <- generateFormPost formUsuario
             defaultLayout $ widgetCss >> 
                 $(whamletFile "templates/menulogado.hamlet") >> 
                 $(whamletFile "templates/footer.hamlet") >> 
                 widgetForm CadastroUsuarioR enctype widget "Usuário"
                 

postCadastroUsuarioR :: Handler Html
postCadastroUsuarioR = do
                ((result, _), _) <- runFormPost formUsuario
                case result of
                    FormSuccess usuario -> do
                       runDB $ insert usuario 
                       defaultLayout [whamlet| 
                           <h1>Usuario inserido com sucesso. 
                       |]
                    _ -> redirect CadastroUsuarioR
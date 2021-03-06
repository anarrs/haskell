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
                      areq (selectField tips) "Tipo" Nothing
tips = do
       entidades <- runDB $ selectList [] [Asc TipoNome] 
       optionsPairs $ fmap (\ent -> (tipoNome $ entityVal ent, entityKey ent)) entidades

formCadastroTipo :: Form Tipo
formCadastroTipo = renderDivs $ Tipo <$>
                   areq textField "Nome" Nothing

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
     widgetScript >> 
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

--fTipo :: Int -> Tipo
--fTipo x = ttipo <- runDB $ selectFirst [TipoId ==. x]

getHomeR :: Handler Html
getHomeR = do
          -- let ttipo = map entityKey
         --  ttipo <- runDB $ selectFirst [TipoId ==. 2] []
           --ttipo <- runDB $ get404 2
        --   listaN <- runDB $ selectList [NoticiaIdtipo ==. entityKey ttipo] [Desc NoticiaId, LimitTo 8]
           listaN <- runDB $ selectList [] [Desc NoticiaId, LimitTo 8]
          -- listaN <- runDB $ rawSql 
        --     "SELECT * FROM noticia INNER JOIN tipo ON noticia.idtipo=tipo.id"
           defaultLayout $ widgetCss >> 
               $(whamletFile "templates/menu.hamlet") >> 
               $(whamletFile "hamlet/destaque.hamlet") >> 
               $(whamletFile "hamlet/noticias.hamlet") >> 
               [whamlet| 
               <div class="text-center">
                   <a href=@{NoticiasR} class="btn btn-danger">
                       + notícias 
               |] >>
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
                 widgetScript >> 
                 widgetForm CadastroNoticiaR enctype widget "Noticia"
                 

postCadastroNoticiaR :: Handler Html
postCadastroNoticiaR = do
                ((result, _), _) <- runFormPost formCadastroNoticia
                case result of
                    FormSuccess noticia -> do
                       runDB $ insert noticia 
                       setMessage $ [shamlet| <p class="text-center"> Noticia inserida com sucesso |]
                       redirect CadastroNoticiaR
                    _ -> redirect CadastroNoticiaR

getCadastroTipoR :: Handler Html
getCadastroTipoR = do
             (widget, enctype) <- generateFormPost formCadastroTipo
             defaultLayout $ widgetCss >> 
                 $(whamletFile "templates/menulogado.hamlet") >> 
                 $(whamletFile "templates/footer.hamlet") >> 
                 widgetScript >> 
                 widgetForm CadastroTipoR enctype widget "Tipo"
                 

postCadastroTipoR :: Handler Html
postCadastroTipoR = do
                ((result, _), _) <- runFormPost formCadastroTipo
                case result of
                    FormSuccess tipo -> do
                       runDB $ insert tipo 
                       setMessage $ [shamlet| <p class="text-center"> Tipo inserido com sucesso |]
                       redirect CadastroTipoR
                    _ -> redirect CadastroTipoR



getCadastroImagemR :: Handler Html
getCadastroImagemR = do
             (widget, enctype) <- generateFormPost formCadastroImagem
             defaultLayout $ widgetCss >> 
                 $(whamletFile "templates/menulogado.hamlet") >> 
                 $(whamletFile "templates/footer.hamlet") >> 
                 widgetScript >> 
                 widgetForm CadastroImagemR enctype widget "Imagem"
                 

postCadastroImagemR :: Handler Html
postCadastroImagemR = do
                ((result, _), _) <- runFormPost formCadastroImagem
                case result of
                    FormSuccess imagem -> do
                       runDB $ insert imagem 
                       setMessage $ [shamlet| <p class="text-center"> Imagem inserida com sucesso |]
                       redirect CadastroImagemR
                    _ -> redirect CadastroImagemR

getCadastroUsuarioR :: Handler Html
getCadastroUsuarioR = do
             (widget, enctype) <- generateFormPost formUsuario
             defaultLayout $ widgetCss >> 
                 $(whamletFile "templates/menulogado.hamlet") >> 
                 $(whamletFile "templates/footer.hamlet") >> 
                 widgetScript >> 
                 widgetForm CadastroUsuarioR enctype widget "Usuário"
                 

postCadastroUsuarioR :: Handler Html
postCadastroUsuarioR = do
                ((result, _), _) <- runFormPost formUsuario
                case result of
                    FormSuccess usuario -> do
                       runDB $ insert usuario 
                       setMessage $ [shamlet| <p class="text-center"> Usuario inserida com sucesso |]
                       redirect CadastroUsuarioR
                    _ -> redirect CadastroUsuarioR
                    

getListaNoticiasR :: Handler Html
getListaNoticiasR = do
             listaN <- runDB $ selectList [] [Asc NoticiaId]
             defaultLayout $ widgetCss >> 
                 $(whamletFile "templates/menulogado.hamlet") >> 
                 $(whamletFile "templates/footer.hamlet") >> 
                 widgetScript >> 
                 [whamlet|
                 <h1> Noticias cadastradas:
                 $forall Entity nid noticia <- listaN
                     <a href=@{NoticiaR nid}> #{noticiaTitulo noticia} 
                     <form method=post action=@{NoticiaR nid}> 
                         <input type="submit" value="Deletar"><br>
             |] >> toWidget [lucius|
                form  { display:inline; }
                input { background-color: #ecc; border:0;}
             |]

getNoticiaR :: NoticiaId -> Handler Html
getNoticiaR nid = do
             noticia <- runDB $ get404 nid 
             listaI <- runDB $ selectList [ImagemIdnoticia ==. nid ] []
             defaultLayout $ widgetCss >> 
                 $(whamletFile "templates/menu.hamlet") >> 
                 $(whamletFile "hamlet/noticia.hamlet") >> 
                 $(whamletFile "templates/footer.hamlet") >> 
                 widgetScript

postNoticiaR :: NoticiaId -> Handler Html
postNoticiaR nid = do
     runDB $ delete nid
     redirect ListaNoticiasR
     
     

getListaImagensR :: Handler Html
getListaImagensR = do
             listaI <- runDB $ selectList [] [Asc ImagemId]
             defaultLayout $ widgetCss >> 
                 $(whamletFile "templates/menulogado.hamlet") >> 
                 $(whamletFile "templates/footer.hamlet") >> 
                 widgetScript >> 
                 [whamlet|
                 <h1> Imagens cadastradas:
                 $forall Entity iid imagem <- listaI
                     <img src=#{imagemUrl imagem}> 
                     <form method=post action=@{ImagemR iid}> 
                         <input type="submit" value="Deletar"><br>
             |] >> toWidget [lucius|
                form  { display:inline; }
                input { background-color: #ecc; border:0;}
             |]

postImagemR :: ImagemId -> Handler Html
postImagemR iid = do
     runDB $ delete iid
     redirect ListaImagensR
     
getListaUsuariosR :: Handler Html
getListaUsuariosR = do
             listaU <- runDB $ selectList [] [Asc UsuarioId]
             defaultLayout $ widgetCss >> 
                 $(whamletFile "templates/menulogado.hamlet") >> 
                 $(whamletFile "templates/footer.hamlet") >> 
                 widgetScript >> 
                 [whamlet|
                 <h1> Usuarios cadastradas:
                 $forall Entity uid usuario <- listaU
                     #{usuarioNome usuario} 
                     <form method=post action=@{UsuarioR uid}> 
                         <input type="submit" value="Deletar"><br>
             |] >> toWidget [lucius|
                form  { display:inline; }
                input { background-color: #ecc; border:0;}
             |]

postUsuarioR :: UsuarioId -> Handler Html
postUsuarioR uid = do
     runDB $ delete uid
     redirect ListaUsuariosR
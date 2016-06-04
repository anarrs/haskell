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


widgetCss2 :: Widget
widgetCss2 = do
    addStylesheetRemote "http://fonts.googleapis.com/css?family=Open+Sans:400,300,600,700,800"
    addStylesheetRemote "http://fonts.googleapis.com/css?family=Arvo"
    addStylesheet $ StaticR css_colors_green_css
    addStylesheet $ StaticR css_style_css
    addStylesheet $ StaticR css_base_css
    addStylesheet $ StaticR css_responsive_css
    addStylesheet $ StaticR css_font_awesome_css

widgetCss :: Widget
widgetCss = do
    addStylesheet $ StaticR css_bootstrap_css
    addStylesheet $ StaticR css_carousel_customizado_css
    addStylesheet $ StaticR css_sticky_footer_navbar_css

formDepto :: Form Departamento
formDepto = renderDivs $ Departamento <$>
            areq textField "Nome" Nothing <*>
            areq textField FieldSettings{fsId=Just "hident2",
                           fsLabel="Sigla",
                           fsTooltip= Nothing,
                           fsName= Nothing,
                           fsAttrs=[("maxlength","3")]} Nothing

formPessoa :: Form Pessoa
formPessoa = renderDivs $ Pessoa <$>
             areq textField "Nome" Nothing <*>
             areq intField "Idade" Nothing <*>
             areq doubleField "Salario" Nothing <*>
             areq (selectField dptos) "Depto" Nothing

dptos = do
       entidades <- runDB $ selectList [] [Asc DepartamentoNome] 
       optionsPairs $ fmap (\ent -> (departamentoSigla $ entityVal ent, entityKey ent)) entidades

getHomeR :: Handler Html
getHomeR = do
           defaultLayout $ widgetCss >> 
           $(whamletFile "templates/menu.hamlet") >> 
           $(whamletFile "hamlet/destaque.hamlet") >> 
           $(whamletFile "hamlet/noticias_boletim.hamlet")

{-
getHomeR = do
           defaultLayout $ do  
                 addStylesheet $ StaticR css_style_css
                 [whamlet| 
                 <h1>123
                 |]

     
getHomeR = do
           defaultLayout $
                toWidget $(luciusFile "templates/css.lucius") >>
                $(whamletFile "templates/home.hamlet")
-}

-- FUNCAO PARA GERAR FORMULARIOS DE UMA MANEIRA GENERICA
widgetForm :: Route Sitio -> Enctype -> Widget -> Text -> Widget
widgetForm x enctype widget y = $(whamletFile "templates/form.hamlet")

getCadastroR :: Handler Html
getCadastroR = do
             (widget, enctype) <- generateFormPost formPessoa
             defaultLayout $ do 
                 addStylesheet $ StaticR teste_css
                 widgetForm CadastroR enctype widget "Pessoas"

getPessoaR :: PessoaId -> Handler Html
getPessoaR pid = do
             pessoa <- runDB $ get404 pid 
             dpto <- runDB $ get404 (pessoaDeptoid pessoa)
             defaultLayout [whamlet| 
                 <h1> Seja bem-vindx #{pessoaNome pessoa}
                 <p> Salario: #{pessoaSalario pessoa}
                 <p> Idade: #{pessoaIdade pessoa}
                 <p> Departamento: #{departamentoNome dpto}
             |]

getListarR :: Handler Html
getListarR = do
             listaP <- runDB $ selectList [] [Asc PessoaNome]
             defaultLayout $ [whamlet|
                 <h1> Pessoas cadastradas:
                 $forall Entity pid pessoa <- listaP
                     <a href=@{PessoaR pid}> #{pessoaNome pessoa} 
                     <form method=post action=@{PessoaR pid}> 
                         <input type="submit" value="Deletar">aaaa<br>
             |] >> toWidget [lucius|
                form  { display:inline; }
                input { background-color: #ecc; border:0;}
             |]

postCadastroR :: Handler Html
postCadastroR = do
                ((result, _), _) <- runFormPost formPessoa
                case result of
                    FormSuccess pessoa -> do
                       runDB $ insert pessoa 
                       defaultLayout [whamlet| 
                           <h1> #{pessoaNome pessoa} Inseridx com sucesso. 
                       |]
                    _ -> redirect CadastroR

getDeptoR :: Handler Html
getDeptoR = do
             (widget, enctype) <- generateFormPost formDepto
             defaultLayout $ widgetForm DeptoR enctype widget "Departamentos"

postDeptoR :: Handler Html
postDeptoR = do
                ((result, _), _) <- runFormPost formDepto
                case result of
                    FormSuccess depto -> do
                       runDB $ insert depto
                       defaultLayout [whamlet|
                           <h1> #{departamentoNome depto} Inserido com sucesso. 
                       |]
                    _ -> redirect DeptoR

postPessoaR :: PessoaId -> Handler Html
postPessoaR pid = do
     runDB $ delete pid
     redirect ListarR
{-# LANGUAGE TemplateHaskell, QuasiQuotes #-}
module Import where

import Yesod
-- apesar do prof, por preguica, estar usando
-- uma rota / para cadastro. Nao facam em casa.
{-pRoutes = [parseRoutes|
   / CadastroR GET POST
   /hello HelloR GET
   /listar ListarR GET 
   /pessoa/#PessoaId PessoaR GET POST
   /depto DeptoR GET POST
   /static StaticR Static getStatic
|]-}
pRoutes = [parseRoutes|
   / HomeR GET
   /login LoginR GET POST
   /logout LogoutR GET
   /noticias NoticiasR GET
   /noticia/#NoticiaId NoticiaR GET POST
   /imagem/#ImagemId ImagemR POST
   /usuario/#UsuarioId UsuarioR POST
   /cadastronoticia CadastroNoticiaR GET POST
   /cadastroimagem CadastroImagemR GET POST
   /cadastrousuario CadastroUsuarioR GET POST
   /static StaticR Static getStatic
   /listanoticias ListaNoticiasR GET 
   /listaimagens ListaImagensR GET 
   /listausuarios ListaUsuariosR GET 
|]
module Aula13 where

import Control.Applicative

data Produtoz = Produtoz { produtozNome :: String, produtozValor :: Double} deriving Show

{-
Produtoz = tipo
com 1 value constroctor (Produtoz)
Produtoz tem dois campos (produtozNome e produtozValor)
produtozNome e produtozValor = record sitax

produtozNome (Produtoz "teste" 90)
"teste"
*Aula13> produtozValor (Produtoz "teste" 90)
90.0

Produtoz <$> Just "teste" <*> Just 66
-}

--fmap (2*) (Just 10)
--Just 20

--(*2) <$> Just 10
--(*2) $ 10
--(\x -> x+9 )

{-
f com funtir e x com funtor -> <*>
f sem funtir e x com funtor -> <$>
f sem funtir e x sem funtor -> $ ou nada

let soma = \x y -> x+y
soma 5 3
8

let f = Just soma
:t f
f :: Maybe (Integer -> Integer -> Integer)
f <*> Just 5 <*> Just 3
soma <$> Just 5 <*> Just 3


Interpoladores
@ -> Para rotas
# -> comandos haskell

-}
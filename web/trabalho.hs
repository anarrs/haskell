Criar uma tabela
Produto
com os campos nome (Text) e valor (Double)
criar a rota /prod com GET para o form
e POST para a inserção.
--------- curl -----------------------
curl https://hask2-romefeller.c9users.io/cadastro \
  -v \
  -X POST \
  -H 'Content-Type: application/json' \
  -d '{"nome":"EU"}'
  
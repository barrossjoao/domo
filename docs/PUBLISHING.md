# Publicar no GitHub

O código está preparado para um repositório novo. Nenhum repositório remoto ou atualizador automático foi configurado nesta entrega.

## Primeiro envio

Crie um repositório vazio no GitHub, sem README ou outros arquivos iniciais. Escolha a visibilidade desejada. Na pasta do projeto:

```bash
cd ~/Documents/domo
git init -b main
git add .
git status --short
```

Confira os arquivos antes do commit. `.build`, `dist`, arquivos de ambiente, certificados e chaves privadas estão no `.gitignore`. O login pessoal fica no Chaves do macOS, fora do projeto.

Depois de conferir:

```bash
git commit -m "Prepare Domo for GitHub"
```

Copie o comando `git remote add origin` mostrado na página do seu repositório e execute-o. Em seguida:

```bash
git push -u origin main
```

Não envie o `.app` na árvore de código. Distribua o pacote compilado como anexo de uma release.

## Compilação no GitHub

O workflow `.github/workflows/build.yml` roda em pushes, pull requests e acionamento manual. Ele usa um runner macOS, executa `make build` e `make verify`, e disponibiliza o ZIP como artefato do workflow. Não usa credenciais da Positivo, não executa o app e não publica releases automaticamente.

As ações oficiais estão fixadas por commit: [checkout](https://github.com/actions/checkout/releases/tag/v7.0.1) e [upload-artifact](https://github.com/actions/upload-artifact/releases/tag/v7.0.2). O runner está documentado em [GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).

O artefato tem assinatura ad hoc para desenvolvimento. Assinatura Developer ID e notarização da Apple são etapas separadas para distribuição pública.

## Release manual

1. Incremente a versão e o build em `Resources/Info.plist` e atualize o README.
2. Execute `make build` e `make verify` ou aguarde a compilação do workflow.
3. Crie uma release com uma tag correspondente, por exemplo `v2.2.8`.
4. Anexe o ZIP do aplicativo e descreva as mudanças e os limites conhecidos.

O ZIP do código-fonte e o ZIP do aplicativo são entregas diferentes. O primeiro contém os arquivos de desenvolvimento; o segundo contém o `.app` instalável.

## Atualizações pelo aplicativo

Esta etapa aguarda a criação do repositório. Publicar uma release, por si só, ainda não atualiza os apps instalados.

Depois que houver uma URL definitiva, a integração poderá usar [Sparkle](https://sparkle-project.org/documentation/) para consultar versões e instalar pacotes verificados por assinatura. Será necessário definir o feed de versões, guardar a chave privada de assinatura fora do código e configurar a publicação dos pacotes assinados. Nenhuma chave, endereço fictício ou rotina de autoatualização foi adicionada agora.

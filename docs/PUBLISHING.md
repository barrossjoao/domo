# Publicar versões do Domo

Repositório público: [barrossjoao/domo](https://github.com/barrossjoao/domo). As versões instaláveis e o feed ficam em [Releases](https://github.com/barrossjoao/domo/releases).

## Publicação automática

1. Incremente o último número de `CFBundleShortVersionString` e o inteiro `CFBundleVersion` em `Resources/Info.plist`. Os dois precisam ser maiores que os da última release.
2. Atualize README e CHANGELOG, compile com `make build` e confira com `make verify`.
3. Faça o commit, crie a tag correspondente e envie o código e a tag. Exemplo para esta versão:

```bash
cd ~/Documents/domo
git add .
git commit -m "Add signed automatic updates"
git tag v2.2.9
git push origin main v2.2.9
```

O workflow `release.yml` confere a tag, verifica os scripts de publicação, compila para **arm64 e x86_64**, inspeciona o pacote e gera o ZIP e o feed assinados. Só depois cria a release com os dois anexos. A etapa de assinatura exige o secret `SPARKLE_PRIVATE_KEY` do repositório; na ausência dele, a publicação falha. Não substitua anexos de uma versão já publicada: corrija e publique uma versão nova.

O fluxo regular `build.yml` compila branches e pull requests e disponibiliza artefatos de desenvolvimento sem usar a chave de release. Nenhum workflow executa o app, acessa contas Positivo ou roda Swift Tests. As ações estão fixadas por commit.

## O que o aplicativo faz

Da versão **2.2.9** em diante, o Sparkle consulta o feed abaixo a cada hora, enquanto o Domo estiver aberto:

```text
https://github.com/barrossjoao/domo/releases/latest/download/appcast.xml
```

O feed assinado aponta para o ZIP da release específica. O app valida o feed e o arquivo usando a chave pública embarcada, antes da extração. Por padrão, baixa atualizações e instala ao encerrar; se permanecer aberto por um dia após baixar, pode oferecer a instalação e reinicialização. O botão **Buscar atualizações…** permite iniciar o fluxo imediatamente. As preferências de atualização do Sparkle são respeitadas.

Um commit ou uma release sem o feed e o pacote assinados não atualiza o aplicativo. Versões anteriores à 2.2.9 precisam de uma substituição manual inicial. Extraia o `.app` e mantenha-o numa pasta gravável, preferencialmente Aplicativos. As releases incluem ambas as arquiteturas para não oferecer um pacote incompatível com o Mac.

## Chaves e recuperação

- **Pública:** `SUPublicEDKey` em `Info.plist`; pode estar no repositório.
- **Privada neste Mac:** Chaves, item Sparkle de assinatura, conta `domo-releases`.
- **Privada no GitHub:** secret de Actions `SPARKLE_PRIVATE_KEY`, disponibilizado somente à etapa de assinatura de tags do repositório de origem. O conteúdo nunca deve entrar no código, em argumentos de processo ou nos logs.

Mantenha um backup protegido do Chaves ou da chave, fora deste repositório. O secret do GitHub não permite recuperar seu valor pela interface. Não gere uma chave nova para cada versão. Perder a chave impede continuar o canal atual; uma troca exige planejar migração e, sem Developer ID, pode exigir reinstalação manual.

## Gerar uma release localmente

Com a chave já no Chaves:

```bash
python3 scripts/build_app.py --universal
python3 scripts/prepare_release.py --tag v2.2.9
```

Os arquivos em `dist/release` são o ZIP universal e `appcast.xml`, já assinados e verificados. Os caches, binários e chaves ficam fora do Git. `Package.resolved` é versionado para reproduzir a dependência Sparkle.

## Assinatura e distribuição

A assinatura **EdDSA do Sparkle** protege os downloads do atualizador e é independente da assinatura Apple. O bundle principal continua com assinatura ad hoc; Developer ID e notarização não estão configurados. O macOS pode exigir a liberação manual da primeira instalação baixada do GitHub. Os componentes oficiais do Sparkle preservam suas assinaturas originais.

Referências: [configuração do Sparkle](https://sparkle-project.org/documentation/), [comportamento automático](https://sparkle-project.org/documentation/customization/) e [publicação de atualizações](https://sparkle-project.org/documentation/publishing/).

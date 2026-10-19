# Domo

## Versionamento

- Em cada atualização entregue, incremente somente o último número de `CFBundleShortVersionString` em `Resources/Info.plist`: `2.2.0` → `2.2.1` → `2.2.2`.
- Incremente também `CFBundleVersion` e atualize a versão informada no README e no nome do arquivo ZIP entregue.
- Recompilações e correções durante a mesma atualização mantêm a versão daquela entrega.
- Gere novamente o `.app` e confira que sua versão corresponde à configuração do projeto antes de entregar.

## Publicação

- Atualizações instaláveis são releases assinadas, não commits isolados. Após validar uma entrega, envie uma tag `vX.Y.Z` correspondente ao `Info.plist` para acionar `.github/workflows/release.yml`.
- Mantenha `Package.resolved` versionado. Nunca troque `SUPublicEDKey` sem planejar a migração das instalações existentes.
- A chave privada fica no Chaves (conta Sparkle `domo-releases`) e no secret `SPARKLE_PRIVATE_KEY` do GitHub. Nunca copie seu conteúdo para o código, argumentos, logs ou artefatos.

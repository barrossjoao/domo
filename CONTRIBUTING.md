# Contribuir com o Domo

O projeto usa SwiftUI e AppKit, com um único módulo organizado por responsabilidade. Requer macOS 13+, Xcode ou Command Line Tools com Swift 5.9+ e Python 3 para empacotamento.

## Desenvolvimento

```bash
make build
make verify
```

Abra `Package.swift` no Xcode para editar. Formate as mudanças com `make format`.

As views ficam em `Features`, o estado compartilhado em `App/HouseStore.swift` e o protocolo Positivo em `Services/Positivo`. Use as capacidades cadastradas no controle; o infravermelho não confirma o estado físico do aparelho.

## Verificação

Compile o app e confira o pacote com os comandos acima. Para mudanças nos controles, use respostas simuladas em vez de acionar aparelhos reais. O workflow do GitHub compila, verifica e empacota; ele não executa o app nem os Swift Tests.

Os testes XCTest existentes podem ser executados localmente com `swift test` quando necessário. Nunca inclua uma conta real em testes, exemplos, capturas ou logs.

## Versões e publicação

Cada entrega incrementa o último número de `CFBundleShortVersionString` e também `CFBundleVersion`, em `Resources/Info.plist`. Atualize a versão no README e o nome do ZIP. Recompilações da mesma entrega mantêm a versão.

Consulte [Publicar no GitHub](docs/PUBLISHING.md) para o primeiro envio e as releases. Tokens, certificados e chaves privadas não pertencem ao repositório. A atribuição e a licença do protocolo adaptado ficam em `Licenses`.

Para publicar uma atualização instalável, siga [PUBLISHING.md](docs/PUBLISHING.md). O Sparkle é fixado em `Package.swift` e `Package.resolved`; uma mudança nessa dependência exige verificar o framework embarcado e seu licenciamento. Não altere a chave pública nem a identidade do bundle sem planejar compatibilidade.

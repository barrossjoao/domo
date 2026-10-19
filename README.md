# Domo

**Sua casa na barra de menus do Mac.**

Versão **2.2.9**.

Aplicativo nativo para controlar a TV e o ar-condicionado pelo Smart Controle Universal da Positivo. Feito em **SwiftUI + AppKit**, com conexão direta à nuvem Positivo/Tuya.

**macOS 13+ · SwiftUI + AppKit · Atualizações com Sparkle · Sem runtime web**

<details>
<summary>Ver o aplicativo</summary>

<img src="docs/images/domo.png" width="360" alt="Painel azul do ar-condicionado em prévia com comandos simulados">
<img src="docs/images/television.png" width="360" alt="Controle azul da TV com direcional circular, volume, canais e atalhos; comandos simulados">
<img src="docs/images/login.png" width="360" alt="Login com campos nativos em cartões azuis; prévia sem conexão à nuvem">

Prévia visual com comandos simulados, sem conexão aos aparelhos.

</details>

## O que o app faz

- **Login com o mesmo visual dos controles:** campos nativos em cartões azuis, foco visível, atalhos de colagem e botão com estado de carregamento.
- **Login lembrado:** o acesso fica no Chaves deste Mac. Ao reabrir, o app tenta reutilizar a sessão e renova o login quando a nuvem informa que ela expirou.
- **Menu bar:** o painel abre pelo ícone de casa e fecha ao clicar fora, ativar outro aplicativo ou trocar de Space. Iniciar o app ou abrir outra cópia não faz o painel aparecer. Ao abrir novamente, ele se ajusta à tela do ícone clicado.
- **Ar-condicionado:** painel azul sem rolagem, com aparelho ilustrado, fluxo de ar animado, temperatura em destaque e cartões de modo e ventilação. A barra permite arrastar ou usar as setas do teclado; as alterações são enviadas automaticamente. Um único botão de energia alterna entre Ligar e Desligar com um clique, sem menus. A próxima ação muda após o envio aceito; em caso de erro, ela é mantida.
- **TV:** painel azul com direcional circular e OK iluminado, volume e canais nas laterais e atalhos para início, voltar, menu e silêncio. Números, guia, último canal e mídia abrem em painéis rápidos, sem alongar o controle principal. Somente as teclas cadastradas aparecem.
- **Funções adicionais:** encontre as outras teclas por categoria e busca em um popover separado.
- **Atualizações automáticas:** consulta releases a cada hora, baixa pacotes verificados e instala quando o app é encerrado. Para conferir e instalar antes, use **Buscar atualizações…** no menu de opções ou no clique direito do ícone. Se o app permanecer aberto por um dia após baixar, o Sparkle pode oferecer a instalação e reinicialização.
- **Janela ampliada:** abra o mesmo painel em uma janela maior, compartilhando a sessão e as seleções.

O fluxo de ar tem traços contínuos e muda de velocidade sem saltar ao alterar a ventilação. Os números usam a transição nativa de dígitos no macOS 14+ e um fade no macOS 13. Ao arrastar a barra, o cursor segue o mouse continuamente e se acomoda no valor mais próximo ao soltar, com brilho acompanhando a temperatura.

O painel do ar cabe na área da barra de menus sem rolagem e sem os textos do rodapé. Em áreas menores, os espaços são compactados; em janelas muito baixas, a ilustração dá lugar aos controles. Erros continuam acessíveis por um indicador no cabeçalho. A barra de temperatura mantém o ajuste por teclado sem o contorno azul de foco no macOS 14+.

A TV compartilha a paleta e a resposta visual dos botões do ar, com brilho ao passar o mouse e animação ao pressionar. Volume e canais usam comandos relativos, sem exibir valores ou estados que o infravermelho não consegue confirmar. Os nomes das teclas coloridas ficam no painel de mídia, mantendo a interface azul.

O painel mantém o azul em todos os modos; o gradiente quente aparece somente na barra de temperatura. As animações respeitam a opção **Reduzir movimento** do macOS. A ilustração representa os ajustes desejados, sem medir a temperatura do ambiente ou o funcionamento físico do aparelho.

A alternância de energia do ar usa os comandos aceitos nesta execução do app, separadamente para cada controle. Sem histórico, a primeira ação é Ligar. Ajustes de temperatura, modo ou ventilação aceitos passam a oferecer Desligar; o app não mede o estado físico. Usar outro controle remoto pode deixar essa referência diferente do aparelho. Reiniciar ou desconectar limpa a referência.

Somente os comandos disponíveis no controle cadastrado são usados. Abrir o painel, conectar a conta ou consultar os dispositivos não aciona os aparelhos.

## Instalar e usar

Se o aplicativo já foi gerado:

1. Abra `dist/Domo.app`, ou copie-o para a pasta **Aplicativos**.
2. Clique no ícone de casa na barra de menus.
3. Conecte a mesma conta do aplicativo **Positivo Casa Inteligente**. Os campos de e-mail e senha aceitam **⌘V**; **⌘A** seleciona todo o conteúdo para substituí-lo.
4. Escolha a TV ou o ar-condicionado.

Fechar o painel ou sair do aplicativo mantém o acesso salvo para a próxima abertura. **Desconectar** encerra a sessão local, remove o acesso do Chaves e exige um novo login. Não há inicialização automática configurada.

Na primeira abertura da versão 2.2.2, faça login uma vez: as versões anteriores não guardavam esse acesso. Depois disso, a recuperação acontece automaticamente. Se o Mac estiver sem internet, o acesso salvo é preservado e o painel oferece **Tentar reconectar**, sem exigir que você digite a senha novamente. Se o macOS solicitar acesso ao Chaves, autorize o Domo para usar seu login salvo.

## Publicar no GitHub

O projeto inclui workflow de compilação e verificação no GitHub Actions, `.gitignore` para artefatos e chaves, e um [guia do primeiro envio e das releases](docs/PUBLISHING.md). Para colaborar, consulte [CONTRIBUTING.md](CONTRIBUTING.md).

As versões instaláveis ficam nas [Releases do Domo](https://github.com/barrossjoao/domo/releases). O workflow de publicação compila para **Apple silicon e Intel**, assina o ZIP e o feed e publica os dois juntos ao receber uma tag `vX.Y.Z`. Um commit isolado não é uma atualização instalável.

**Instale a versão 2.2.9 uma vez para ativar o atualizador.** A 2.2.8 e anteriores não conseguem buscar atualizações. Mantenha o `.app` extraído numa pasta gravável, preferencialmente **Aplicativos**; não execute de dentro do ZIP ou de uma imagem de disco. A chave pública embarcada valida o feed e o download antes da extração.

## Compilar

Requisitos de desenvolvimento:

- macOS 13 ou superior;
- Xcode ou Command Line Tools com Swift 5.9+;
- Python 3, usado apenas para empacotar e inspecionar o `.app`.

```bash
cd ~/Documents/domo
make build
open dist/Domo.app
```

O aplicativo é compilado para a arquitetura do Mac que executa o comando. A geração acontece numa pasta temporária e só substitui o pacote existente após compilar e verificar a assinatura.

Para editar no Xcode, abra **Package.swift**. O projeto é um pacote Swift padrão. O SwiftPM baixa o Sparkle **2.10.0**, fixado no manifesto e em `Package.resolved`; o framework acompanha o `.app`, sem instalação separada.

## Estrutura do projeto

```text
domo/
├── .github/workflows/
│   ├── build.yml                     # Compilação de branches e pull requests
│   └── release.yml                   # Release universal com pacote e feed assinados
├── CHANGELOG.md                     # Notas das versões
├── CONTRIBUTING.md                  # Guia de desenvolvimento
├── Package.swift                    # Configuração do pacote e dos testes
├── Makefile                         # Comandos de desenvolvimento
├── README.md
├── Sources/Domo/
│   ├── App/
│   │   ├── DomoApp.swift             # Entrada do executável
│   │   ├── AppUpdater.swift          # Ciclo de atualização nativo com Sparkle
│   │   ├── MenuBarAppDelegate.swift  # Menu bar, popover e janela
│   │   └── HouseStore.swift          # Estado compartilhado e ações
│   ├── Features/
│   │   ├── Authentication/
│   │   │   └── LoginView.swift
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.swift   # Composição da tela principal
│   │   │   ├── DeviceControlsView.swift
│   │   │   └── HouseTheme.swift      # Paleta azul e interação dos botões
│   │   ├── Climate/
│   │   │   ├── ClimateControlView.swift
│   │   │   ├── ClimateUnitIllustration.swift # Aparelho e fluxo de ar em SwiftUI
│   │   │   ├── ClimateTemperatureText.swift  # Transição dos dígitos
│   │   │   └── TemperatureBar.swift  # Barra com mouse, teclado e VoiceOver
│   │   └── Television/
│   │       └── TVRemoteView.swift
│   ├── Models/
│   │   ├── RemoteModels.swift        # Controles, comandos e ajustes do ar
│   │   └── RemoteCatalog.swift       # Tradução e classificação das teclas
│   └── Services/Positivo/
│       ├── PositivoClient.swift     # HTTPS, login, descoberta e infravermelho
│       ├── SavedLogin.swift         # Dados de acesso e contrato do armazenamento
│       ├── KeychainLoginStorage.swift # Persistência no Chaves do macOS
│       ├── MobileCrypto.swift       # Assinatura e criptografia do protocolo
│       └── PositivoError.swift      # Erros apresentados ao usuário
├── Tests/DomoTests/
│   ├── App/                         # Estado, seleções e envio automático
│   ├── Models/                      # Catálogo e códigos dos controles
│   ├── Services/                    # Criptografia e cliente Positivo
│   ├── Support/                     # Transporte simulado e leitura de fixtures
│   └── Fixtures/                    # Dados sintéticos usados pelos testes
├── Resources/
│   └── Info.plist                   # Identidade e configuração do app macOS
├── Licenses/
│   ├── positivo-integration-MIT.txt
│   └── Sparkle.txt
├── scripts/
│   ├── build_app.py                 # Compilação, empacotamento e assinatura
│   ├── verify_app.py                # Inspeção estática do pacote gerado
│   ├── prepare_release.py           # Pacote universal e feed assinados
│   └── tests/                       # Validações do processo de release
├── docs/
│   ├── ARCHITECTURE.md               # Fluxos e decisões de arquitetura
│   ├── PUBLISHING.md                 # Primeiro envio e releases no GitHub
│   └── images/
└── dist/                            # Resultado gerado; ignorado pelo Git
```

## Como as partes se conectam

```text
Views SwiftUI → HouseStore → PositivoClient → HTTPS → Positivo/Tuya
                                    ↓
                              MobileCrypto
```

As views cuidam da apresentação. O `HouseStore` concentra a sessão visível, as seleções e a fila de comandos. O `PositivoClient` conhece o protocolo externo. Modelos e catálogo mantêm os códigos separados da interface.

Há **um único módulo de aplicativo**, organizado por responsabilidade. Não existem repositórios genéricos, camadas de serviços duplicadas ou interfaces sem um segundo uso concreto.

Leia [a documentação da arquitetura](docs/ARCHITECTURE.md) para acompanhar os fluxos de login, descoberta e envio.

## Comandos de desenvolvimento

| Comando | Resultado |
| --- | --- |
| `swift build` | Compila o pacote em modo de desenvolvimento |
| `make build` | Gera o `.app` em modo release com assinatura local |
| `make run` | Gera e abre o aplicativo |
| `make verify` | Inspeciona metadados, assinatura, Sparkle e ausência de runtime web |
| `python3 scripts/build_app.py --universal` | Gera o app para Apple silicon e Intel |
| `python3 -m unittest discover -s scripts/tests` | Verifica as validações de publicação |
| `swift test` | Executa os testes XCTest com respostas de nuvem simuladas |
| `make format` | Formata os arquivos Swift com `swift-format` |

Os testes não precisam de uma conta real e não enviam comandos aos seus aparelhos. As fixtures incluem vetores de referência para MD5/HMAC e RSA, além de exemplos das teclas dos controles.

## Privacidade e limites

- O app acessa a Positivo/Tuya por **HTTPS** usando `URLSession`.
- E-mail, senha, sessão e identificador do dispositivo ficam no **Chaves do macOS**, sem sincronização solicitada pelo app. Não são gravados em arquivos do projeto ou em preferências comuns.
- O Sparkle consulta o feed público de releases via HTTPS, sem enviar o login Positivo; perfil de sistema está desativado. Suas preferências de atualização ficam no domínio do app.
- As preferências de login guardam apenas a opção de reconexão automática. **Desconectar** desativa essa opção antes de remover o item do Chaves; mesmo se o macOS negar a remoção, o app não restaura a conta automaticamente.
- A renovação tenta autenticar uma vez após uma recusa explícita de sessão expirada. Falhas de rede não apagam o acesso salvo nem repetem comandos de infravermelho automaticamente.
- As constantes do aplicativo OEM identificam a integração; elas não são credenciais pessoais.
- A interface é SwiftUI/AppKit, sem Node.js ou servidor local. A interface de atualização também é nativa. As notas de versão web do Sparkle estão desativadas; seus recursos padrão acompanham o framework sem mudar os controles do Domo.
- **A conexão ainda exige internet.** Não há implementação de controle offline ou pela rede local.
- O infravermelho não confirma o estado físico do aparelho. “Enviado” indica que a nuvem aceitou o pedido.
- Esta é uma integração não oficial e depende da continuidade do serviço Positivo/Tuya.

## Versionamento

Cada atualização entregue incrementa o último número da versão: **2.2.0 → 2.2.1 → 2.2.2 → 2.2.3 → 2.2.4 → 2.2.5 → 2.2.6 → 2.2.7 → 2.2.8 → 2.2.9**. A regra está registrada em [AGENTS.md](AGENTS.md). A versão do aplicativo fica em `Resources/Info.plist` e também aparece no menu de opções do painel. Recompilar a mesma entrega não incrementa a versão.

`make verify` confere se a versão e o número do build embarcados correspondem aos do projeto, além de inspecionar o pacote nativo.

## Distribuição e atribuição

O pacote é assinado **ad hoc para uso local**. Distribuição pública com Developer ID e notarização da Apple é uma etapa separada.

O protocolo foi adaptado do projeto comunitário [unofficial-positivo-pcuirn](https://github.com/gabriellhuver/unofficial-positivo-pcuirn). A licença MIT original está preservada em [Licenses/positivo-integration-MIT.txt](Licenses/positivo-integration-MIT.txt) e acompanha o aplicativo gerado.

As atualizações usam [Sparkle](https://sparkle-project.org/), com licença e avisos de terceiros preservados em [Licenses/Sparkle.txt](Licenses/Sparkle.txt). A assinatura EdDSA dos pacotes e do feed protege o canal de atualização; ela é independente da assinatura Developer ID e da notarização Apple.

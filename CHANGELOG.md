# Changelog


## 2.2.9

- Atualizador nativo Sparkle, com consulta automática ao GitHub a cada hora, download verificado e instalação ao encerrar o aplicativo.
- Ação Buscar atualizações no painel, menu principal e clique direito do ícone, respeitando o estado do atualizador.
- Feed e pacotes assinados com EdDSA, verificação antes da extração, sem notas web nem perfil de sistema.
- Releases universais para Apple silicon e Intel publicadas pelo GitHub Actions ao enviar uma tag correspondente à versão.
- Validações de empacotamento, assinaturas e metadados de release; licença do Sparkle incluída no aplicativo.

A 2.2.8 e anteriores precisam ser substituídas uma vez para receber o atualizador. A assinatura Developer ID e a notarização Apple continuam separadas.

## 2.2.8

- O aplicativo passa a se chamar Domo, incluindo módulo Swift, executável, pasta do projeto, documentação e pacotes.
- A identidade de armazenamento foi preservada para continuar usando o login salvo.

## 2.2.7

- O ar-condicionado volta a ter um único botão de energia, alternando entre Ligar e Desligar com um clique.
- A próxima ação acompanha os envios aceitos por controle e é preservada quando o envio falha.
- Projeto preparado para o GitHub, com compilação e verificação pelo Actions, documentação de contribuição e publicação, e exclusão de artefatos e chaves pelo Git.
- Atualizações automáticas aguardam a criação do repositório; ainda não foram ativadas.

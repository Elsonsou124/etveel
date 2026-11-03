# ðŸš€ Assistente de FormataÃ§Ã£o Pro (AutomaÃ§Ã£o PÃ³s-FormataÃ§Ã£o)

Ferramenta de automaÃ§Ã£o para Windows, desenvolvida em **Batch (CMD)** e **PowerShell**, com interface grÃ¡fica em **Windows Forms**. O menu reÃºne instalaÃ§Ãµes de aplicativos e algumas configuraÃ§Ãµes do sistema para tarefas comuns apÃ³s uma formataÃ§Ã£o.

> [!WARNING]
> O script solicita privilÃ©gios de administrador e altera configuraÃ§Ãµes de seguranÃ§a e energia do Windows. Leia a seÃ§Ã£o [Avisos importantes](#-avisos-importantes) antes de executar. NÃ£o rode em um computador de produÃ§Ã£o sem revisar e testar o cÃ³digo.

---

## ðŸ› ï¸ O que o programa faz?

O **Assistente de FormataÃ§Ã£o Pro** oferece aÃ§Ãµes individuais e pacotes de instalaÃ§Ã£o, acompanha os processos em segundo plano e mostra mensagens de status na interface. TambÃ©m aplica configuraÃ§Ãµes do Windows ao iniciar.

### âœ¨ Principais funcionalidades

1. **ElevaÃ§Ã£o de privilÃ©gios:** verifica se estÃ¡ executando como administrador e, se necessÃ¡rio, solicita elevaÃ§Ã£o pelo Windows.

2. **ConfiguraÃ§Ãµes aplicadas na inicializaÃ§Ã£o:**
   - Define os tempos de desligamento da tela e suspensÃ£o como â€œnuncaâ€ e desativa a hibernaÃ§Ã£o.
   - Altera entradas do Registro relacionadas aos Ã­cones da Ãrea de Trabalho e Ã s extensÃµes associadas ao Visualizador de Fotos clÃ¡ssico.
   - Tenta atualizar a Ãrea de Trabalho para refletir as alteraÃ§Ãµes.
   - **Altera o Microsoft Defender:** tenta desativar a proteÃ§Ã£o em tempo real e a proteÃ§Ã£o de comportamento. O botÃ£o **Sair** tenta reativÃ¡-las; fechar a janela por outro meio nÃ£o executa esse trecho.
   - ContÃ©m uma rotina que grava um arquivo `rarreg.key` no diretÃ³rio do WinRAR. Os dados inseridos nÃ£o sÃ£o uma licenÃ§a oficial validada.

3. **InstalaÃ§Ã£o e acompanhamento de aplicativos:** usa o `winget` para Chrome, Acrobat Reader, WinRAR e MSI Afterburner. A interface acompanha logs de sucesso, itens jÃ¡ instalados e erros.

4. **IntegraÃ§Ã£o com o Office:** extrai um instalador embutido em Base64 para uma pasta temporÃ¡ria e o inicia. Nas opÃ§Ãµes com Office, o script espera o instalador fechar e entÃ£o tenta copiar os atalhos encontrados para `Ãrea de Trabalho/Office 365`.

---

## ðŸ’» Tecnologias utilizadas

- **Batch (CMD):** inicializaÃ§Ã£o e verificaÃ§Ã£o de privilÃ©gios.
- **PowerShell:** lÃ³gica de automaÃ§Ã£o, processos e configuraÃ§Ãµes do Windows.
- **Windows Forms (.NET):** interface grÃ¡fica, botÃµes, barra de progresso e painel de logs.
- **WinGet:** instalaÃ§Ã£o de aplicativos compatÃ­veis.

---

## ðŸ“‹ AÃ§Ãµes disponÃ­veis na interface

| AÃ§Ã£o / botÃ£o | DescriÃ§Ã£o |
| :--- | :--- |
| **AtivaÃ§Ã£o Windows** | Executa uma rotina externa obtida de `get.activated.win`. Consulte os avisos: nÃ£o Ã© uma ferramenta oficial da Microsoft. |
| **Instalar Google Chrome** | Instala o Google Chrome pelo `winget`. |
| **Instalar WinRAR** | Instala o WinRAR pelo `winget` e executa a rotina de gravaÃ§Ã£o do arquivo `rarreg.key`. |
| **Instalar MSI Afterburner** | Instala o MSI Afterburner pelo `winget`; em caso de erro, o menu pode abrir a pÃ¡gina da MSI. |
| **Instalar Apenas o Office** | Extrai e inicia o instalador de Office embutido; ao fechar o instalador, tenta copiar os atalhos. |
| **Copiar Atalhos do Office** | Procura atalhos do Office no Menu Iniciar e tenta copiÃ¡-los para `Ãrea de Trabalho/Office 365`. |
| **TUDO (Sem MSI e sem Office)** | Tenta instalar Chrome, Acrobat Reader e WinRAR. |
| **INSTALAR TUDO (Sem MSI)** | Tenta instalar Chrome, Acrobat Reader, WinRAR e Office; apÃ³s fechar o instalador do Office, tenta copiar os atalhos. |
| **INSTALAR TUDO + Office** | Tenta instalar Chrome, Acrobat Reader, WinRAR, MSI Afterburner e Office; apÃ³s fechar o instalador do Office, tenta copiar os atalhos. |

---

## ðŸŽ¨ Interface visual

- Tema escuro com detalhes em ciano e verde.
- BotÃµes numerados para aÃ§Ãµes individuais e pacotes.
- Painel de status, barra de progresso e logs com horÃ¡rio.

---

## âš™ï¸ Como utilizar

1. Baixe o arquivo `.bat` principal deste repositÃ³rio.
2. Revise o cÃ³digo e confirme que confia na origem antes de executar.
3. Execute o arquivo. Se necessÃ¡rio, o Windows exibirÃ¡ uma solicitaÃ§Ã£o de administrador.
4. Escolha uma aÃ§Ã£o e acompanhe o status e os logs na interface.
5. Para as opÃ§Ãµes com Office, aguarde o instalador terminar e feche sua janela; o menu entÃ£o tenta copiar os atalhos.

O `winget` e os instaladores precisam de conexÃ£o com a internet. Algumas instalaÃ§Ãµes podem depender de configuraÃ§Ãµes do computador ou exibir solicitaÃ§Ãµes prÃ³prias.

---

## âš ï¸ Avisos importantes

- **Defender:** a proteÃ§Ã£o em tempo real e a proteÃ§Ã£o de comportamento sÃ£o alteradas ao abrir o script. Se a janela for fechada pelo **X**, pelo Gerenciador de Tarefas ou por uma falha, o botÃ£o **Sair** nÃ£o serÃ¡ acionado. Verifique o estado do Defender apÃ³s o uso.
- **Energia e hibernaÃ§Ã£o:** as configuraÃ§Ãµes aplicadas nÃ£o sÃ£o restauradas automaticamente ao fechar o programa.
- **AtivaÃ§Ã£o do Windows:** o botÃ£o executa cÃ³digo obtido da internet em PowerShell oculto. O conteÃºdo remoto pode mudar e nÃ£o Ã© fornecido pela Microsoft. Revise a origem e use apenas mÃ©todos compatÃ­veis com sua licenÃ§a.
- **WinRAR:** o arquivo de registro criado pelo script contÃ©m dados de licenÃ§a nÃ£o oficial e nÃ£o comprova uma licenÃ§a vÃ¡lida. Para distribuiÃ§Ã£o pÃºblica, remova essa rotina e use uma licenÃ§a legÃ­tima.
- **Instalador do Office:** o script extrai e executa o arquivo embutido, mas nÃ£o valida sua origem nem sua assinatura antes de iniciÃ¡-lo. Verifique o arquivo antes de usar.
- **Atalhos do Office:** a cÃ³pia depende de os atalhos jÃ¡ existirem no Menu Iniciar. O fechamento do instalador, por si sÃ³, nÃ£o garante que o Office terminou de configurar ou que os atalhos foram criados.
- **Interface:** a posiÃ§Ã£o do botÃ£o **Sair** usa a variÃ¡vel `$y`, que nÃ£o estÃ¡ definida no script; o botÃ£o pode aparecer em posiÃ§Ã£o incorreta.

Teste em uma mÃ¡quina virtual ou ambiente descartÃ¡vel antes de usar em outros computadores. NÃ£o apresente o projeto como instalador oficial da Microsoft, Google, Adobe, MSI ou WinRAR.

---

## ðŸ‘¤ Autor

Criado por **Elson** (*Criatividade E Tudo*).

## ðŸ“„ LicenÃ§a

Nenhuma licenÃ§a de uso ou distribuiÃ§Ã£o foi especificada. Adicione uma licenÃ§a somente se tiver os direitos necessÃ¡rios sobre o cÃ³digo e os componentes incluÃ­dos.

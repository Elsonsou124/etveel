# 🚀 Assistente de Formatação Pro (Automação Pós-Formatação)

Uma poderosa ferramenta de automação para Windows desenvolvida em **Batch (CMD)** e **PowerShell**, com interface gráfica moderna em **Windows Forms**. O menu reúne instalações de aplicativos e configurações do sistema para otimizar tarefas comuns após uma formatação.

> [!AVISO]
> O script solicita privilégios de administrador e altera configurações de segurança e energia do Windows. Leia atentamente a seção [Avisos Importantes](#avisos-importantes) antes de executar. Não rode em um computador de produção sem revisar e testar o código.

---

## 🛠️ O que o programa faz?

O **Assistente de Formatação Pro** oferece ações individuais e pacotes de instalação, acompanha os processos em segundo plano e exibe mensagens de status detalhadas na interface. Também aplica configurações cruciais do Windows ao iniciar.

### ✨ Principais Funcionalidades

1. **Elevação de Privilégios:**
   * Verifica automaticamente se está executando como Administrador e, caso contrário, solicita a elevação de privilégios (`RunAs`) pelo Windows de forma transparente.

2. **Configurações Aplicadas na Inicialização:**
   * **Gerenciamento de Energia:** Define os tempos de desligamento de tela e suspensão como "nunca" e desativa o recurso de hibernação por completo para evitar interrupções.
   * **Registro do Windows:** Altera entradas do Registro para restaurar ícones clássicos na Área de Trabalho e associar o clássico *Visualizador de Fotos* (`Windows Photo Viewer`) a extensões comuns (`.jpg`, `.png`, `.bmp`, etc.).
   * **Atualização do Explorer:** Força um *refresh* na Área de Trabalho para refletir as alterações instantaneamente.
   * **Microsoft Defender:** Tenta desativar temporariamente a proteção em tempo real e de comportamento durante o uso (o botão **Sair** tenta reativá-las; fechamentos forçados por outros meios não executam essa reversão).
   * **Registro Automático WinRAR:** Contém uma rotina que grava um arquivo `rarreg.key` no diretório do WinRAR (atenção: os dados inseridos não constituem uma licença oficial validada).

3. **Instalação e Acompanhamento de Aplicativos:**
   * Utiliza o **Winget** (Windows Package Manager) para instalar pacotes essenciais (Chrome, Acrobat Reader, WinRAR, MSI Afterburner) com logs em tempo real na interface, detalhando sucessos, itens já instalados e eventuais erros.

4. **Integração com o Microsoft Office:**
   * Extrai um instalador embutido em Base64 para uma pasta temporária e o executa. Nas opções com Office, o script aguarda o instalador fechar e tenta copiar automaticamente os atalhos encontrados para a pasta `Área de Trabalho/Office 365`.

---

## 💻 Tecnologias Utilizadas

* **Batch (CMD):** Inicialização, checagem de ambiente e chamada do motor PowerShell.
* **PowerShell:** Lógica de automação de processos, comandos e manipulação do sistema operacional.
* **Windows Forms (.NET):** Construção da interface gráfica (GUI), contendo botões dinâmicos, barra de progresso, painéis estilizados e console de logs.
* **Winget:** Gerenciador de pacotes oficial da Microsoft para instalação limpa de softwares.

---

## 📋 Ações Disponíveis na Interface

| Ação / Botão | Descrição |
| :--- | :--- |
| **Ativação Windows** | Abre diretamente a tela de Configurações de Ativação do Windows no seu sistema. |
| **Instalar Google Chrome** | Instala o navegador Google Chrome de forma silenciosa via `winget`. |
| **Instalar WinRAR** | Instala o WinRAR via `winget` e executa a rotina de gravação do arquivo de registro. |
| **Instalar MSI Afterburner** | Instala o MSI Afterburner; em caso de falha no pacote, abre a página oficial da MSI. |
| **Instalar Apenas o Office** | Extrai e inicia o instalador do Office embutido e gerencia a cópia posterior de atalhos. |
| **Copiar Atalhos do Office** | Varre o Menu Iniciar e tenta copiar atalhos limpos do Office para `Área de Trabalho/Office 365`. |
| **TUDO (Sem MSI e sem Office)** | Fila automatizada para Chrome, Acrobat Reader e WinRAR. |
| **INSTALAR TUDO (Sem MSI)** | Fila completa incluindo Chrome, Acrobat Reader, WinRAR e Office + cópia de atalhos. |
| **INSTALAR TUDO + Office** | Instalação massiva de todo o ecossistema (Chrome, Acrobat Reader, WinRAR, Afterburner e Office). |

---

## 🎨 Design e Interface Visual

* **Tema Escuro Profundo:** Paleta de cores moderna com tons escuros e destaques em ciano e verde, ideal para bancadas técnicas.
* **Feedback Visual Completo:** Barra de progresso dinâmica, status de execução atual e console de logs com marcação horária (`HH:mm:ss`).

---

## ⚠️ Avisos Importantes

> **Atenção aos pontos abaixo antes de utilizar o script em ambientes de produção:**

* **Windows Defender:** A proteção em tempo real e de comportamento são modificadas ao abrir o script. Se a janela for fechada pelo **X**, pelo Gerenciador de Tarefas ou por falhas, o botão **Sair** não será acionado. Verifique o estado do Defender após o uso.
* **Energia e Hibernação:** As configurações aplicadas não são restauradas automaticamente ao fechar o programa.
* **Ativação do Windows:** O botão executa código obtido da internet em PowerShell oculto. O conteúdo remoto pode mudar e não é fornecido pela Microsoft. Revise a origem e utilize apenas métodos compatíveis com sua licença.
* **WinRAR:** O arquivo de registro criado pelo script contém dados de licençating não oficial e não comprova uma licença válida. Para distribuição pública, remova essa rotina e utilize uma licençating legítima.
* **Instalador do Office:** O script extrai e executa o arquivo embutido, mas não valida sua origem ou assinatura antes de iniciá-lo. Verifique o arquivo previamente.
* **Atalhos do Office:** A cópia depende de os atalhos já existirem no Menu Iniciar. O fechamento do instalador por si só não garante que a configuração do Office terminou ou que os atalhos foram gerados com sucesso.
* **Interface:** A posição do botão **Sair** utiliza a variável `$y`, que pode não estar estritamente definida dependendo do escopo do loop; o botão pode apresentar variação na posição dependendo do ambiente.

*Dica: Teste sempre em uma máquina virtual ou ambiente descartável antes de aplicar em computadores de clientes ou de produção. Não apresente o projeto como instalador oficial da Microsoft, Google, Adobe, MSI ou WinRAR.*

---

## 👤 Autor

Criado por **Elson** (*Criatividade E Tudo*).

## 📄 Licença

Nenhuma licençating de uso ou distribuição foi especificada. Adicione uma licença somente se possuir os direitos necessários sobre o código e os componentes incluídos.

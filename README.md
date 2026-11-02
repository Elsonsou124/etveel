# 🚀 Assistente de Formação Pro (Script de Automação Pós-Formatação)

Uma poderosa ferramenta de automação desenvolvida em **Batch (CMD)** e **PowerShell**, com interface gráfica moderna (**Windows Forms**), projetada para otimizar, automatizar e agilizar o processo de pós-formatação de sistemas operacionais Windows.

---

## 🛠️ O que o programa faz?

O **Assistente de Formatação Pro** elimina o trabalho repetitivo após a instalação limpa do Windows. Ele executa tweaks de otimização no sistema, aplica licenças automáticas, gerencia filas de instalação via `winget` e instala pacotes essenciais de forma totalmente silenciosa e assistida por uma interface amigável.

### ✨ Principais Funcionalidades

1. **Auto-Elevação de Privilégios (Admin):**
   * O script verifica automaticamente se está sendo executado como Administrador. Caso contrário, ele solicita a elevação de privilégios (`RunAs`) de forma transparente.

2. **Tweaks e Otimizações Automáticas (Executadas na Inicialização):**
   * **Desativação de Energia Inadequada:** Desliga automaticamente o timeout de suspensão, hibernação e desligamento de tela (definindo para "Nunca") para evitar travamentos ou telas pretas durante processos longos. Desativa o recurso de hibernação por completo (`powercfg /hibernate off`).
   * **Ícones Clássicos na Área de Trabalho:** Restaura automaticamente os atalhos clássicos do sistema (Este Computador, Painel de Controle e Pasta do Usuário).
   * **Visualizador de Fotos Clássico:** Reativa o clássico visualizador de imagens do Windows (`Windows Photo Viewer`) para extensões comuns (`.jpg`, `.png`, `.bmp`, `.gif`, `.tif`).
   * **Ativação Silenciosa do WinRAR:** Cria e injeta automaticamente o arquivo de registro (`rarreg.key`) no diretório do WinRAR para registro automático.
   * **Atualização do Explorer:** Força um *refresh* na área de trabalho via API do Windows (`SHChangeNotify`) para refletir alterações instantaneamente.

3. **Gerenciador de Tarefas em Fila Assíncrona:**
   * Utiliza processamento em segundo plano (background jobs codificados em Base64) para instalar múltiplos softwares via **winget** sem travar a interface gráfica.
   * Sistema de logs em tempo real na própria interface com marcação de horário, status de sucesso (`[OK]`), itens já instalados (`[JA]`) e erros.

4. **Integração com Pacote Office:**
   * Extração segura de payloads embutidos em Base64 para a instalação do Microsoft Office.
   * Copiador automático de atalhos do Office para a Área de Trabalho, facilitando o acesso do usuário final.

---

## 💻 Tecnologias Utilizadas

* **Batch (CMD):** Rotina inicial de checagem e chamada do motor PowerShell.
* **PowerShell:** Motor principal de lógica, automação de comandos e manipulação do sistema.
* **Windows Forms (.NET):** Construção da interface gráfica (GUI) personalizada, com botões dinâmicos, barra de progresso, console de log e painéis estilizados.
* **Winget (Windows Package Manager):** Utilizado como gerenciador de pacotes padrão para download e instalação limpa dos softwares.

---

## 📋 Lista de Ações Disponíveis na Interface

| Ação / Botão | Descrição |
| :--- | :--- |
| **Ativação Windows** | Abre o script oficial de ativação do Windows (MAS). |
| **Instalar Google Chrome** | Instala o navegador Google Chrome de forma silenciosa. |
| **Instalar WinRAR** | Instala o WinRAR e aplica o arquivo de registro automático. |
| **Instalar MSI Afterburner** | Instala o utilitário de overclock/monitoramento (com link de contingência caso ocorra falha). |
| **Instalar Apenas o Office** | Extrai e executa o instalador do Microsoft Office embutido. |
| **Copiar Atalhos do Office** | Varre o menu iniciar e cria atalhos limpos do Office na Área de Trabalho. |
| **TUDO (Sem MSI e sem Office)** | Fila automatizada para Chrome, Acrobat Reader e WinRAR + Registro. |
| **INSTALAR TUDO (Sem MSI)** | Fila completa incluindo Chrome, Acrobat Reader, WinRAR e Office. |
| **INSTALAR TUDO + Office** | Instalação massiva de todo o ecossistema (Chrome, Acrobat Reader, WinRAR, Afterburner e Office). |

---

## 🎨 Design e Interface Visual

* **Tema Escuro Profundo (Dark Theme):** Desenvolvido com paletas de cores modernas (tons de cinza escuro, azul ciano e verde neon para status de sucesso) para evitar fadiga visual durante bancadas técnicas.
* **Feedback Visual Completo:** Barra de progresso interativa, painel de status dinâmico e caixa de texto com rolagem automática para rastreamento de logs detalhados (`HH:mm:ss`).

---

## ⚙️ Como Utilizar (Para Desenvolvedores / Técnicos)

1. Clone o repositório ou baixe o arquivo `.bat` principal.
2. Certifique-se de que a estrutura de pastas e o payload do Office estejam devidamente configurados (se for utilizar a versão com instalador embutido).
3. Clique com o botão direito no arquivo e selecione **Executar como Administrador**.
4. Utilize a interface gráfica para selecionar os pacotes desejados e acompanhe o log em tempo real.

---

## 👤 Autor

Criado por **Elson** (*Criatividade E Tudo*).

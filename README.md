# Prova de Conceito: Instrumentação de Aplicações Legadas com eBPF e Grafana Beyla

<p align="center"> <img src="https://grafana.com/media/blog/beyla-opentelemetry/meta6.png?w=764" style="display: block; margin-left: auto; margin-right: auto;"/> </p>

<p align="center">
<a href="https://grafana.com/docs/beyla/latest/">
<img src="https://img.shields.io/badge/Grafana-Beyla-blue" alt="Grafana Beyla"/>
</a>
<a href="https://ebpf.io/">
<img src="https://img.shields.io/badge/eBPF-Linux%20Kernel-green" alt="eBPF"/>
</a>
</p>

## Introdução

Esta Prova de Conceito (PoC) demonstra uma abordagem moderna para a instrumentação de **aplicações legadas** utilizando **eBPF (extended Berkeley Packet Filter)** e **Grafana Beyla**.

O objetivo principal é demonstrar como coletar **métricas e traces** de forma **automática e sem a necessidade de alterar o código-fonte** (uma abordagem no-code). Esta solução é valiosa para equipes de DevOps e SRE que enfrentam o desafio de monitorar sistemas antigos, onde a instrumentação tradicional é inviável, arriscada ou simplesmente impossível devido à falta de bibliotecas compatíveis.

## O Desafio da Observabilidade em Aplicações Legadas

Monitorar aplicações legadas com ferramentas modernas, como o OpenTelemetry, apresenta barreiras significativas. As abordagens tradicionais geralmente falham por duas razões principais:

1.  **Instrumentação Manual:**

    - **Risco Elevado:** Exige modificar o código-fonte, o que pode introduzir bugs ou quebrar funcionalidades em sistemas críticos que ninguém ousa tocar.
    - **Complexidade:** Aplicações legadas frequentemente possuem bases de código extensas, monolíticas e com baixo nível de documentação, tornando a edição manual uma tarefa árdua e perigosa.
    - **Falta de Suporte:** Muitas linguagens antigas (como Perl, COBOL ou versões arcaicas de Java/Python) podem não ter SDKs de telemetria modernos e confiáveis.

2.  **Instrumentação Automática (Agentes Tradicionais):**

    - **Limitações de Linguagem:** A maioria dos agentes automáticos ainda depende de _hooks_ em _runtimes_ específicas (ex: Java Agents, Python monkey-patching), não cobrindo todas as linguagens.
    - **Coleta Genérica:** Muitas vezes, a coleta é superficial ou "barulhenta", poluindo dashboards com métricas genéricas e dificultando a identificação de problemas reais.

### A Solução: eBPF + Grafana Beyla

A combinação de eBPF e Beyla contorna esses problemas ao operar em um nível mais fundamental: o kernel do Linux.

- **Agnóstico à Linguagem:** Como observa chamadas de sistema (syscalls) e tráfego de rede, funciona com qualquer linguagem (Perl, Java, Python, Go, C++, etc.).
- **Zero Alteração de Código (_No-code_):** A aplicação não precisa ser modificada, eliminando o risco de quebra.
- **Métricas Essenciais (RED):** Foca nativamente nas métricas de ouro da observabilidade: **R**ate (taxa de requisições), **E**rrors (taxa de erros) e **D**uration (duração).
- **Baixo Overhead:** O eBPF executa código de forma nativa e segura dentro do kernel, resultando em um impacto de performance mínimo.

O resultado é uma **observabilidade profunda** para sistemas legados, fornecendo os dados necessários para pavimentar um caminho seguro para a modernização.

## 🔬 O que é eBPF?

**eBPF (extended Berkeley Packet Filter)** é uma tecnologia revolucionária do **kernel Linux** (disponível de forma robusta desde a versão 4.13+) que permite executar programas em um ambiente _sandbox_ dentro do próprio kernel. Isso tudo **sem alterar o código-fonte do kernel** ou carregar módulos de kernel (LKMs), que são arriscados.

Embora sua origem venha da filtragem de pacotes de rede (BPF), o eBPF moderno é usado para **observabilidade**, **segurança** e **rede** em alto desempenho.

**Analogia:** Pense no eBPF como uma forma de tornar o **kernel programável**, similar a como o JavaScript tornou as páginas web estáticas em aplicações dinâmicas nos navegadores.

### Como Funciona o eBPF?

O processo de execução de um programa eBPF segue etapas rigorosas para garantir a segurança:

1.  **Desenvolvimento:** Programas são escritos em C restrito e compilados para _bytecode_ eBPF.
2.  **Carregamento:** O _bytecode_ é carregado no kernel através da _syscall_ `bpf()`.
3.  **Verificação:** Esta é a etapa crucial. O **Verificador** do kernel analisa estaticamente o _bytecode_ para garantir que ele é seguro:
    - Não entra em loops infinitos.
    - Não acessa memória inválida.
    - Não trava o kernel.
      Programas que falham na verificação são rejeitados.
4.  **Compilação JIT:** Após a verificação, o _bytecode_ é compilado por um compilador **Just-in-Time (JIT)** para código de máquina nativo, garantindo performance máxima.
5.  **Anexação (Attach):** O programa compilado é anexado a um "gatilho" (trigger) no kernel, como:
    - Chamadas de sistema (syscalls).
    - Tracepoints.
    - _kprobes_ (funções do kernel) ou _uprobes_ (funções no espaço do usuário).
    - Eventos de rede.
6.  **Comunicação:** Os programas eBPF podem compartilhar dados (métricas, contadores, logs) com aplicações no espaço do usuário (como o Beyla) de forma eficiente através de estruturas de dados chamadas **"Mapas"** (como _hash maps_, _arrays_ ou _ring buffers_).

### ✅ Prós

| Pró                         | Descrição                                                       |
| --------------------------- | --------------------------------------------------------------- |
| **Sem Alteração de Código** | Nenhuma modificação é necessária na aplicação monitorada.       |
| **Baixo Overhead**          | Execução em velocidade nativa (JIT) dentro do kernel.           |
| **Agnóstico à Linguagem**   | Funciona com qualquer binário ou script, pois observa o kernel. |
| **Seguro por Design**       | O Verificador impede que programas eBPF travem o sistema.       |
| **Visibilidade Rica**       | Acesso direto a syscalls, tráfego de rede e eventos do sistema. |

### ❌ Contras

| Contra                   | Descrição                                                                         |
| ------------------------ | --------------------------------------------------------------------------------- |
| **Kernel Recente**       | Requer um kernel Linux moderno (5.8+ é ideal para recursos avançados).            |
| **Privilégios Elevados** | Requer privilégios de `root` ou a _capability_ `CAP_BPF` para carregar programas. |

## 🛡️ eBPF é Seguro?

**Sim.** A arquitetura do eBPF foi projetada com a segurança como pilar central, permitindo estender as funcionalidades do kernel sem comprometer sua estabilidade.

Isso é garantido por múltiplos mecanismos:

- **O Verificador:** Como mencionado, é um "porteiro" rigoroso que rejeita qualquer código inseguro _antes_ que ele seja executado.
- **Helpers Abstratos:** Programas eBPF não podem chamar funções arbitrárias do kernel. Eles são restritos a um conjunto de funções "helper" seguras e pré-aprovadas.
- **Hardening:** O kernel inclui proteções contra ataques especulativos (como Spectre) e ofuscação de ponteiros.
- **Uso em Produção:** Tecnologias de missão crítica como Cilium (rede), Falco (segurança) e o próprio Google (para infraestrutura) dependem de eBPF em produção massiva.

Os riscos são mitigados garantindo que apenas processos confiáveis (como o Beyla) tenham as permissões necessárias para carregar programas eBPF.

## ⚙️ O que é e como funciona o Grafana Beyla?

**Grafana Beyla** é um coletor de telemetria baseado em eBPF. Ele atua como um agente que **descobre automaticamente** processos de aplicação, anexa _probes_ eBPF a eles e captura dados de transações (HTTP, gRPC, SQL) em trânsito.

O Beyla, então, formata esses dados como métricas (Prometheus) e traces (OpenTelemetry) e os exporta para seu _backend_ de observabilidade preferido (como Grafana, Prometheus, etc.).

### Principais Funcionalidades:

- **Auto-descoberta:** Encontra aplicações em execução (por porta aberta ou metadados).
- **Suporte a Protocolos:** Captura HTTP, gRPC e faz detecção heurística de SQL.
- **Métricas RED:** Gera automaticamente métricas de Rate, Errors e Duration para os serviços.
- **Traces Correlacionados:** Cria _spans_ de trace, permitindo a visualização de transações distribuídas.
- **Integração com Kubernetes:** Enriquece a telemetria com metadados do K8s (pods, namespaces).
- **Simplicidade:** Configurado através de um único arquivo YAML.

### 🏗️ Arquitetura e Fluxo de Dados

O fluxo de trabalho do Beyla é direto e eficiente:

```
[Aplicação Legada (Perl)] ← Probes eBPF (kprobes/uprobes, rede)
            |
            ↓ (Dados coletados via Mapas: ring buffers, hash)
            |
[Agente Beyla (User-Space)] → Exportador OTEL → [Backend (Grafana/Prometheus)]
```

1.  **Descoberta:** O Beyla inicia e, com base no `beyla.yml`, procura por processos (neste caso, escutando na porta `1337`).
2.  **Anexação:** Ao encontrar o `perlapp`, o Beyla carrega seus _probes_ eBPF no kernel e os anexa ao processo alvo e às syscalls de rede relevantes.
3.  **Captura:** Conforme a aplicação Perl recebe requisições HTTP, os _probes_ eBPF interceptam os eventos (ex: `read`/`write` em _sockets_), capturam os dados e os enviam para o agente Beyla no espaço do usuário via _ring buffers_.
4.  **Processamento:** O Beyla enriquece os dados brutos com metadados (ex: `service.name`, _endpoints_) e os transforma em métricas RED e _spans_ de trace.
5.  **Exportação:** Finalmente, ele exporta essa telemetria via OTLP (OpenTelemetry Protocol) para o Grafana Agent, que os armazena.

## 🚀 PoC Prática: Aplicação Perl + Beyla + Grafana

Vamos demonstrar o processo monitorando uma aplicação Perl (usando o framework Mojolicious) com o Beyla, enviando os dados para o _stack_ LGTM (Loki, Grafana, Tempo, Mimir) do Grafana.

### 📋 Requisitos

- **Docker** e **Docker Compose**.
- **Linux kernel 5.8+** (para checar, rode `uname -r`).
- Uma rede Docker pré-criada para os serviços:
  ```bash
  docker network create ebpf_default
  ```

### 📁 Estrutura do Repositório

```
.
├── app/
│   ├── app.pl          # A aplicação Perl (Mojolicious)
│   └── Dockerfile      # Dockerfile para construir a imagem Perl
├── beyla.yml           # Arquivo de configuração do Beyla
├── docker-compose.yml  # Stack: Grafana, Beyla e a App Perl
└── README.md
```

### 🔧 Arquivos Chave (Análise)

Abaixo estão os componentes essenciais desta PoC e o porquê de cada um.

#### 1\. **app/app.pl** - A Aplicação Legada (Simulada)

**Objetivo:** Simular um microsserviço legado. Usamos Perl/Mojolicious por ser um exemplo perfeito de linguagem poderosa, porém menos comum em _stacks_ modernas e sem um SDK OpenTelemetry maduro.

```perl
#!/usr/bin/env perl
use Mojolicious::Lite;

# Endpoint simples de "health check"
get '/' => sub {
    my $c = shift;
    $c->render(text => 'Hello, eBPF + Beyla + Perl!');
};

# Endpoint que simula uma consulta (para detecção heurística de SQL)
get '/products' => sub {
    my $c = shift;
    # A resposta JSON simula o que um banco de dados retornaria
    $c->render(json => { products => [ "book", "pen", "laptop" ] });
};

# Inicia o servidor na porta 1337
app->start('daemon', '-l', 'http://*:1337');
```

#### 2\. **app/Dockerfile** - Containerização da Aplicação

**Objetivo:** Empacotar a aplicação Perl e suas dependências (Mojolicious) em uma imagem Docker.

```dockerfile
FROM perl:latest
# Instala o framework web Mojolicious
RUN cpanm Mojolicious
WORKDIR /usr/src/app
COPY app.pl .
# Expõe a porta que o app.pl escuta
EXPOSE 1337
CMD ["perl", "app.pl"]
```

#### 3\. **beyla.yml** - Configuração Central do Beyla

**Objetivo:** Instruir o Beyla sobre o que monitorar e para onde enviar os dados.

```yaml
log_level: INFO

discovery:
  instrument:
    # Diz ao Beyla para procurar processos escutando na porta 1337
    - open_ports: 1337
      # Define o nome do serviço para a telemetria
      name: perlapp
      namespace: poc-ebpf

attributes:
  # Habilita a inspeção de tráfego para padrões SQL (SELECT, INSERT, etc.)
  heuristic_sql_detect: true

# Configura o destino para onde os traces serão enviados (OTLP/HTTP)
otel_traces_export:
  endpoint: http://grafana:4318
# Configura o destino para onde as métricas serão enviadas
otel_metrics_export:
  endpoint: http://grafana:4318
```

_Nota: Usamos `http://grafana:4318` porque `grafana` é o nome do serviço no `docker-compose.yml`, e a porta `4318` é o receptor OTLP/HTTP padrão._

#### 4\. **docker-compose.yml** - Orquestração da Stack

**Objetivo:** Orquestrar todos os serviços (Grafana, Beyla, App) para que funcionem em conjunto.

```yaml
services:
  # O backend de observabilidade (stack LGTM)
  grafana:
    image: grafana/otel-lgtm
    ports:
      - "3000:3000" # UI do Grafana
      - "4317:4317" # OTLP gRPC
      - "4318:4318" # OTLP HTTP
    networks:
      - ebpf_default

  # O agente eBPF
  beyla:
    image: grafana/beyla:latest
    # ESSENCIAL: Permissões necessárias para o eBPF
    privileged: true
    pid: host
    environment:
      - OTEL_RESOURCE_ATTRIBUTES=deployment.environment=dev
      - BEYLA_CONFIG_PATH=/etc/beyla.yml
      - BEYLA_LOG_LEVEL=INFO
    volumes:
      # Mapeia a configuração local para dentro do container
      - ./beyla.yml:/etc/beyla.yml:ro
      # Mapeia diretórios do host necessários para o eBPF funcionar
      - /sys:/sys:ro
      - /lib/modules:/lib/modules:ro
      - /sys/kernel/security:/sys/kernel/security:ro
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    networks:
      - ebpf_default
    # Garante que o app esteja rodando antes do Beyla tentar descobri-lo
    depends_on:
      - perl-app

  # A aplicação legada
  perl-app:
    build: ./app
    working_dir: /usr/src/app
    volumes:
      - ./app:/usr/src/app
    command: ["perl", "app.pl"]
    ports:
      - "1337:1337"
    networks:
      - ebpf_default

networks:
  ebpf_default:
    external: true
    name: ebpf_default
```

**Por que `privileged: true` e `pid: host`?**

- `privileged: true`: Concede ao container do Beyla as _capabilities_ de Linux necessárias (como `CAP_BPF`) para carregar programas no kernel.
- `pid: host`: Permite que o Beyla veja os processos em execução no _host_ (e em outros containers), o que é essencial para o mecanismo de "descoberta".

### 🎯 Como Rodar

1.  Clone o repositório (se aplicável).
2.  Certifique-se de que a rede Docker existe: `docker network create ebpf_default`
3.  Execute o Docker Compose para construir e iniciar todos os containers:
    ```bash
    docker compose up -d --build
    ```

### ✅ Verificação

1.  **Gere Tráfego para a Aplicação:**
    Abra seu terminal e faça algumas requisições:

    ```bash
    # Teste o endpoint principal
    curl http://localhost:1337/
    # Resposta: "Hello, eBPF + Beyla + Perl!"

    # Teste o endpoint de produtos
    curl http://localhost:1337/products
    # Resposta: {"products":["book","pen","laptop"]}

    # Gere alguns erros (endpoint inexistente)
    curl http://localhost:1337/error
    ```

2.  **Acesse o Grafana:**
    Abra [http://localhost:3000](https://www.google.com/search?q=http://localhost:3000) no seu navegador.

    - **Login:** `admin` / **Senha:** `admin` (pode ser solicitado que você troque a senha no primeiro login).

3.  **Explore as Métricas (RED):**

    - No menu lateral, vá em **Explore**.
    - Selecione o _data source_ **Prometheus**.
    - Na barra de consulta, comece a digitar `beyla_`. Você verá as métricas coletadas, como `beyla_http_server_requests_total`.
    - Selecione `beyla_http_server_requests_total` e clique em "Run query". Você verá as métricas da sua aplicação Perl\!

4.  **Explore os Traces:**

    - No menu lateral, vá em **Explore**.
    - Selecione o _data source_ **Tempo**.
    - Clique em "Search" (ou "Query builder"). Você verá os traces das suas requisições `curl`.
    - Filtre pelo nome do serviço: `service.name="perlapp"`.
    - Clique em um trace para ver os _spans_ detalhados, incluindo o _endpoint_ (ex: `/products`) e o status HTTP.

Você verá métricas RED e traces distribuídos para uma aplicação Perl, **sem ter escrito uma única linha de código de instrumentação**.

## 🎉 Conclusão

Esta Prova de Conceito demonstrou que o Grafana Beyla, impulsionado pelo eBPF, é uma solução poderosa e viável para um dos maiores desafios em SRE: a observabilidade de sistemas legados.

O principal benefício é a capacidade de obter telemetria rica (métricas RED e traces) de aplicações "caixa-preta" sem modificar seu código, reduzindo drasticamente o risco e o esforço de engenharia. Esta abordagem não apenas melhora a resposta a incidentes, mas também pavimenta o caminho para a modernização, fornecendo _baselines_ de performance claros antes de uma migração ou _refactoring_.

Sinta-se à vontade para clonar este repositório, experimentar com outras aplicações (outras linguagens ou binários) e explorar os _dashboards_ gerados. Contribuições, _Issues_ e PRs são sempre bem-vindos\! 🚀

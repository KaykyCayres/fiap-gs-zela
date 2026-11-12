# Computational Thinking with Python

**Zela** · Global Solution 2026 · CitizenTech
Tecnólogo em IA · 1TIAPR-2026 · FIAP

| Integrante | RM |
|---|---|
| Kayky Cayres Vicente da Silva | 575091 |
| Naiara Sousa Soares | 574792 |
| Rafael Medici | 576249 |

## O problema

Depois da triagem, o paciente do pronto-socorro ou da UPA volta para a sala de espera e ninguém acompanha os sinais vitais dele de forma contínua. A Zela é um protótipo de pulseira com ESP32 que acompanha essas leituras.

Nesta disciplina, o grupo construiu o programa em Python que faz este fluxo:

```
Dados informados ou simulados → Programa Python → Classificação em 3 níveis → Orientação ao paciente
```

> **Aviso:** protótipo acadêmico. O programa não faz diagnóstico, não substitui a equipe de saúde e não altera a classificação de risco da triagem. Ele só indica quando vale chamar a enfermagem para uma reavaliação.

## Arquivos desta pasta

| Arquivo | O que é |
|---|---|
| `monitor_pulseira.py` | Programa principal da entrega |
| `medicoes_pulseira_simuladas.csv` | 3.672 leituras **simuladas** de 102 pacientes (36 por paciente, uma a cada 2 minutos simulados) |
| `gerar_medicoes_pulseira.py` | Script que gerou o CSV (não é necessário para rodar o programa) |

## Como executar

Requisito: Python 3.8 ou superior. Não precisa instalar bibliotecas, porque o programa só usa `csv` e `os`, que já vêm com o Python.

Deixe o `.py` e o `.csv` na mesma pasta e rode:

```bash
python monitor_pulseira.py
```

| Opção do menu | O que faz |
|---|---|
| **1** · Ler do CSV | Pede o ID do paciente (1 a 102), classifica todas as leituras dele e mostra um resumo |
| **2** · Digitar | Pede FC e SpO2, valida os valores e repete enquanto o usuário quiser |
| **3** · Demonstração | Roda os 3 cenários de teste com valores fixos |

Na opção 1, bons exemplos são o paciente **1** (sempre normal), o **25** (piora até atenção e melhora) e o **4** (piora até crítico).

## Regras de classificação

As entradas são **frequência cardíaca (FC, em BPM)** e **saturação de oxigênio (SpO2, em %)**. Os limites partem de faixas de referência simplificadas: em repouso, a FC de um adulto costuma ficar entre 60 e 100 BPM, e a SpO2 de uma pessoa saudável, entre 95% e 100%. São regras **só para fins acadêmicos**, não critérios clínicos validados.

| Nível | Regra no código | Orientação exibida |
|---|---|---|
| 🔴 CRÍTICO | `fc >= 130 or spo2 < 90` | Sinais preocupantes. Chame a enfermagem imediatamente ou peça ajuda a quem estiver perto. |
| 🟡 ATENÇÃO | `fc >= 110 or fc < 50 or spo2 < 95` | Sinais fora do esperado. Avise a equipe de enfermagem para uma reavaliação. |
| 🟢 NORMAL | nenhuma das condições acima | Sinais dentro do esperado. Continue aguardando e avise a equipe se sentir algo diferente. |

A regra crítica é testada primeiro, para que o caso mais grave nunca seja classificado como um nível menor. Os limites ficam em constantes no início do código (`FC_ATENCAO`, `FC_CRITICO`, `FC_BAIXA`, `SPO2_ATENCAO`, `SPO2_CRITICO`).

## Requisitos do enunciado

- [x] **Pelo menos 2 entradas:** FC e SpO2, digitadas (`ler_numero`) ou lidas do CSV (`ler_csv`)
- [x] **3 níveis com regras justificadas:** NORMAL, ATENÇÃO e CRÍTICO no método `classificar`
- [x] **Variáveis, operadores, condicionais e laços:** `if / elif / else`, `while` na digitação e na validação, `for` na leitura do CSV, nos cenários e no resumo
- [x] **Listas e dicionários:** `historico` é uma lista de dicionários; `RECOMENDACOES` é um dicionário
- [x] **Funções:** `ler_numero`, `ler_csv`, `digitar_medicoes`, `demonstrar_cenarios` e `main`
- [x] **Classe simples:** `MonitorPaciente`, com os atributos `paciente_id` e `historico` e os métodos `classificar`, `recomendar`, `registrar` e `resumo`
- [x] **3 cenários testados, com classificação e recomendação:** veja abaixo

## Testes realizados

| Teste | Entrada | Resultado |
|---|---|---|
| 1 · Opção 3 | FC 78 / SpO2 98% · FC 115 / SpO2 93% · FC 138 / SpO2 88% | NORMAL, ATENÇÃO e CRÍTICO, cada um com a sua orientação |
| 2 · Opção 1, paciente 4 | 36 leituras do CSV | Normal nas leituras 1 a 7, atenção de 8 a 18 e crítico de 19 a 36; o resumo avisa que houve leitura crítica |
| 3 · Opção 2 | FC 999, depois FC 100 e SpO2 93% | 999 é recusado (fora da faixa de 20 a 250); a leitura válida sai como ATENÇÃO |

Os prints de cada teste estão no documento de entrega (PDF).

## Origem dos dados

Os dados do CSV são **simulados**. O script `gerar_medicoes_pulseira.py` parte do dataset público *"Five vital signs of normal people"* (Zenodo): para cada participante, calcula a mediana das 9 leituras reais e usa esse valor como ponto de partida. Depois aplica um de cinco perfis de demonstração (`ESTAVEL`, `FC_ELEVANDO`, `SPO2_CAINDO`, `COMBINADO` e `RECUPERACAO`) com ruído reprodutível. A coluna `origem_dado` marca todas as linhas como `SIMULADO`. Os valores não representam pacientes reais nem desfechos clínicos.

## ODS

- **ODS 3, Saúde e bem-estar (meta 3.8):** acompanhar o paciente durante a espera torna mais segura uma etapa do atendimento em que hoje não há monitoramento contínuo.
- **ODS 10, Redução das desigualdades (meta 10.2):** a orientação em linguagem simples ajuda quem tem dificuldade de perceber ou relatar uma piora, como idosos e pessoas sozinhas na espera.

## Limitações

- **Regras experimentais:** os limites são simplificados e não consideram idade, histórico nem medicamentos.
- **Só duas variáveis:** temperatura, pressão e movimento não entram nesta classificação.
- **Dados simulados:** as sequências e os perfis do CSV foram inventados para teste.
- **Cada leitura é avaliada isoladamente:** o programa não analisa tendência ao longo do tempo.
- **Sem integração com o ESP32:** as leituras chegam por digitação ou CSV.
- **Orientação, não decisão:** a avaliação e a conduta são sempre dos profissionais de saúde.

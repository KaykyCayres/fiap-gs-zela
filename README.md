<p align="center">
  <img src="Documentacao/marca/zela-banner.png" alt="Zela" width="360">
</p>

<p align="center"><b>Pulseira de monitoramento para quem espera no pronto-socorro.</b></p>

Depois da classificação de risco, o paciente pode passar horas na espera do PS sem ser reavaliado. A Zela é uma pulseira com ESP32 que acompanha frequência cardíaca, SpO2 e temperatura, classifica as leituras em três níveis (normal, atenção e crítico) e avisa no próprio local quando a piora se sustenta.

Global Solution 2026.2 da FIAP, tema CitizenTech, turma 1TIAPR.

> **Protótipo acadêmico.** Não é dispositivo médico validado, não diagnostica e não deve ser usado para decisões clínicas. Os dados das demonstrações são simulados e identificados como tal.

## Como funciona

```
ESP32 + sensores → validação local → NORMAL / ATENÇÃO / CRÍTICO → LED e buzzer + Monitor Serial
CSV de medições → S3 → Lambda → RDS (MySQL) → consultas; CloudWatch registra a execução
Base pública real → limpeza e EDA → Estatística → Árvore de Decisão × MLP
```

## Pastas

| Pasta | Matéria |
|---|---|
| [01-Sensores](01-Sensores) | AI Computer Systems & Sensors |
| [02-Python](02-Python) | Computational Thinking with Python |
| [03-CyberSecurity](03-CyberSecurity) | Cognitive Cyber Security |
| [04-BancoDados](04-BancoDados) | Banco de Dados |
| [05-AWS](05-AWS) | Cloud Computing AWS |
| [06-Estatistica](06-Estatistica) | Estatística Aplicada |
| [07-MachineLearning](07-MachineLearning) | Machine Learning & Modelling |
| [08-RedesNeurais](08-RedesNeurais) | Redes Neurais Artificiais |
| [09-AIChallenges](09-AIChallenges) | AI Challenges |
| [Documentacao](Documentacao) | Escopo, arquitetura e marca |

Todo mundo participa de todas as entregas. Cada pasta tem um README com o que o enunciado pede. Tarefas e prazos ficam no [Trello](https://trello.com/b/yPiOGJUF/zela-gs-20262).

## Como trabalhamos

O Trello mostra quem vai fazer o quê. O GitHub mostra quem fez.

**No Trello**
- Entre como membro nos cartões em que você vai mexer.
- Começou: puxe o cartão para **Fazendo**. Terminou: mande para **Revisão**, e outra pessoa confere antes de ir para **Feito**.

**No GitHub**
- Cada um commita da própria conta, na pasta da matéria.
- Comece a mensagem com a sigla da matéria e diga o que mudou:

| Sigla | Matéria | Exemplo |
|---|---|---|
| `[SENS]` | Sensores | `[SENS] adiciona leitura do potenciômetro de SpO2` |
| `[PY]` | Python | `[PY] cria classe Leitura com os 3 níveis` |
| `[CYBER]` | Cyber Security | `[CYBER] valida CSV adulterado` |
| `[BD]` | Banco de Dados | `[BD] cria trigger de alerta` |
| `[AWS]` | AWS | `[AWS] Lambda grava o CSV no RDS` |
| `[EST]` | Estatística | `[EST] tabela de frequência da SpO2` |
| `[ML]` | Machine Learning | `[ML] separa treino e teste` |
| `[RN]` | Redes Neurais | `[RN] compara 2 configurações da MLP` |
| `[AIC]` | AI Challenges | `[AIC] roteiro do vídeo` |
| `[DOC]` | Documentação | `[DOC] atualiza a arquitetura` |

- Dê `git pull` antes de começar, para não sobrescrever o trabalho de ninguém.

## Regras do repositório

- Nada de `.env`, chave da AWS ou senha do banco no git. Use variáveis de ambiente.
- Nada de dado pessoal real. Paciente é sempre pseudonimizado.
- Commits pequenos, com mensagem dizendo o que mudou.

## Equipe

Naiara, Rafael e Kayky.

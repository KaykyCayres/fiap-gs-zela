<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="Documentacao/marca/zela-logo-escuro.svg">
    <img src="Documentacao/marca/zela-logo-claro.svg" alt="Zela" width="280">
  </picture>
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

| Pasta | Matéria | Responsável |
|---|---|---|
| [01-Sensores](01-Sensores) | AI Computer Systems & Sensors | Rafa |
| [02-Python](02-Python) | Computational Thinking with Python | Rafa |
| [03-CyberSecurity](03-CyberSecurity) | Cognitive Cyber Security | Naiara |
| [04-BancoDados](04-BancoDados) | Banco de Dados | Naiara |
| [05-AWS](05-AWS) | Cloud Computing AWS | Naiara |
| [06-Estatistica](06-Estatistica) | Estatística Aplicada | Rafa (EDA com Kayky) |
| [07-MachineLearning](07-MachineLearning) | Machine Learning & Modelling | Kayky |
| [08-RedesNeurais](08-RedesNeurais) | Redes Neurais Artificiais | Kayky |
| [09-AIChallenges](09-AIChallenges) | AI Challenges | Kayky |
| [Documentacao](Documentacao) | Escopo, arquitetura e marca | Todos |

Cada pasta tem um README com o que o enunciado pede. Tarefas e prazos ficam no [Trello](https://trello.com/b/yPiOGJUF/zela-gs-20262).

## Regras do repositório

- Nada de `.env`, chave da AWS ou senha do banco no git. Use variáveis de ambiente.
- Nada de dado pessoal real. Paciente é sempre pseudonimizado.
- Commits pequenos, com mensagem dizendo o que mudou.

## Equipe

Naiara, Rafa e Kayky.

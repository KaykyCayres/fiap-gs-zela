# AI Computer Systems & Sensors (AICSS)

**Zela** · Global Solution 2026 · CitizenTech

| Integrante | RM |
|---|---|
| Kayky Cayres Vicente da Silva | 575091 |
| Naiara Sousa Soares | 574792 |
| Rafael Medici | 576249 |

## O que é

Depois da triagem, o paciente do pronto-socorro fica na sala de espera sem ninguém acompanhando os sinais vitais dele. A Zela é uma pulseira com ESP32 que lê esses sinais, decide se está tudo bem e avisa ali mesmo, com luz e som.

> Protótipo acadêmico: não faz diagnóstico e não substitui a equipe de saúde.

## Componentes

| Componente | Para que serve | Pino |
|---|---|---|
| DS18B20 | Temperatura | GPIO 4 |
| MPU6050 | Movimento (se o paciente está se mexendo) | SDA 21 · SCL 22 |
| Potenciômetro | Simula a frequência cardíaca (FC) | GPIO 34 |
| Potenciômetro | Simula a oxigenação (SpO2) | GPIO 35 |
| Botão | Paciente pede ajuda | GPIO 33 |
| LED verde, amarelo e vermelho | Mostram o estado | GPIO 25 · 26 · 27 |
| Buzzer | Alerta sonoro | GPIO 14 |

FC e SpO2 usam potenciômetros porque o sensor certo (MAX30102) não existe no Wokwi.

## Como funciona

A cada 2 segundos, o ESP32 lê os sensores e classifica:

| Estado | Quando | Alerta |
|---|---|---|
| 🔴 CRÍTICO | FC ≥ 130, SpO2 < 90 ou temperatura ≥ 39,0 °C | LED vermelho e bipe longo |
| 🟡 ATENÇÃO | FC ≥ 110, FC < 50, SpO2 < 95, temperatura ≥ 37,8 °C ou botão apertado | LED amarelo e bipe curto |
| 🟢 NORMAL | Nenhuma das condições acima | LED verde |

Se o paciente estiver se mexendo muito, a leitura aparece como `QUAL=INSTAVEL`, porque o movimento atrapalha a medição.

Cada leitura vira uma linha no Monitor Serial:

```
t=12s | FC=78 SpO2=98 TEMP=36.5 MOV=0.0 QUAL=OK PEDIDO=NAO | ESTADO=NORMAL | motivo: sinais dentro do esperado | Continue aguardando
```

## Como rodar

1. Abra o projeto no Wokwi com o `app.ino` e o `diagram.json` desta pasta.
2. Instale as bibliotecas: OneWire, DallasTemperature, Adafruit MPU6050 e Adafruit Unified Sensor.
3. Inicie a simulação e teste:
   - gire os potenciômetros para mudar FC e SpO2;
   - clique no DS18B20 para mudar a temperatura;
   - clique no MPU6050 para simular movimento;
   - aperte o botão para pedir ajuda.

Os prints dos testes estão no documento de entrega (PDF).

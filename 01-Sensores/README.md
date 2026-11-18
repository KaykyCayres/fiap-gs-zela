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
| DHT22 | Temperatura (simula o sensor de temperatura corporal da pulseira) | GPIO 4 |
| LCD 16x2 I2C | Mostra só a orientação ao paciente, em texto curto | SDA 21 · SCL 22 |
| Potenciômetro | Simula a frequência cardíaca (FC), no lugar do MAX30102 | GPIO 34 |
| Potenciômetro | Simula a oxigenação (SpO2), no lugar do MAX30102 | GPIO 35 |
| LED verde, amarelo e vermelho | Mostram o estado | GPIO 25 · 26 · 27 |
| Buzzer | Alerta sonoro | GPIO 14 |

FC e SpO2 usam potenciômetros porque o sensor certo (MAX30102) não existe no Wokwi. No protótipo, o DHT22 simula o sensor de temperatura corporal da pulseira e os dois potenciômetros simulam o MAX30102 (FC e SpO2), porque o grupo não tem esses sensores.

## Como funciona

A cada 2 segundos, o ESP32 lê os sensores e classifica:

| Estado | Quando | Alerta |
|---|---|---|
| 🔴 CRÍTICO | FC ≥ 130, SpO2 < 90 ou temperatura ≥ 39,0 °C | LED vermelho e bipe longo |
| 🟡 ATENÇÃO | FC ≥ 110, FC < 50, SpO2 < 95, temperatura ≥ 37,8 °C | LED amarelo e bipe curto |
| 🟢 NORMAL | Nenhuma das condições acima | LED verde |

A tela LCD 16x2 mostra só a orientação ao paciente, em texto curto e sem acento, com a mesma mensagem do programa em Python. No CRÍTICO aparece "Chame enfermagem / JA ou peca ajuda", no ATENÇÃO "Sinais alterados / Avise enfermagem" e no NORMAL "Aguarde e avise / se sentir algo". A tela só é reescrita quando o estado muda.

Cada leitura vira uma linha no Monitor Serial:

```
t=12s | FC=78 SpO2=98 TEMP=36.5 FONTE=SENSOR | ESTADO=NORMAL | motivo: sinais dentro do esperado | Continue aguardando
```

O campo `FONTE` diz de onde vieram os valores: `SENSOR` quando foram lidos dos sensores, ou `TESTE(FC,SpO2,TEMP)` quando foram forçados por um comando de teste (veja "Modo de teste").

## Como rodar

1. Abra a pasta do projeto no VS Code (com as extensões PlatformIO e Wokwi).
2. Compile com o PlatformIO (ícone de visto na barra azul, ou `pio run`). O `wokwi.toml` usa o firmware gerado na compilação, então **compile sempre que mudar o `app.ino`**. Sem isso, o Wokwi mostra "firmware.bin not found".
3. Aperte F1 e rode `Wokwi: Start Simulator`.
4. Teste girando os potenciômetros (FC e SpO2), clicando no DHT22 (temperatura). O resultado aparece no Monitor Serial, nos LEDs e na tela LCD.

As bibliotecas (DHT sensor library e LiquidCrystal_I2C) são instaladas pelo PlatformIO, a partir do `platformio.ini`.

## Modo de teste

Para testar sem girar potenciômetro nem clicar nos sensores, dá para forçar valores digitando comandos no Monitor Serial (e apertando Enter, uma linha por vez). A leitura acontece na hora e o LED muda.

**Testes prontos**

| Comando | O que faz |
|---|---|
| `teste1` a `teste6` | Roda o teste inteiro: passa sozinho pelas etapas (uma a cada 6 segundos) e termina no estado final |
| `teste3b` | Aplica só uma etapa (a, b ou c) do teste 3 e fica nela. Vale para qualquer teste: `teste4c`, `teste6a`... |
| `proximo` (ou `p`) | Passa para a etapa seguinte do teste em andamento |
| `auto` | Volta a ler todos os sensores e encerra o teste |

**Valores soltos**

| Comando | O que faz |
|---|---|
| `fc 125` | Força a FC em 125 BPM (aceita de 20 a 250) |
| `spo2 85` | Força a SpO2 em 85% (50 a 100) |
| `temp 39.1` | Força a temperatura em 39,1 °C (30 a 45) |
| `auto fc` | Volta só a FC a vir do sensor (também `auto spo2` e `auto temp`) |
| `ajuda` | Mostra a lista de comandos |

Sem comando, a leitura vem sempre dos sensores. Valores fora da faixa são recusados. Nesse modo, os potenciômetros e os sensores do desenho não se mexem: o valor é trocado no código, e o campo `FONTE=TESTE(...)` mostra isso em cada linha.

## Testes realizados

| Teste | Entrada | Resultado | Comando |
|---|---|---|---|
| 1 · Paciente estável | FC 78 · SpO2 98% · 36,5 °C | NORMAL, LED verde | `teste1` |
| 2 · Frequência cardíaca alta | FC 104 → 125 | NORMAL → ATENÇÃO (motivo: FC alta), LED amarelo | `teste2` |
| 3 · Oxigenação caindo | SpO2 98 → 93 → 85% | NORMAL → ATENÇÃO (SpO2 baixa) → CRÍTICO (SpO2 muito baixa), LED vermelho | `teste3` |
| 4 · FC no limite e SpO2 muito baixa | FC 125 → 129 e SpO2 100 → 86% | Com FC 129 ainda é ATENÇÃO (o limite crítico é 130); com SpO2 86% vira CRÍTICO | `teste4` |
| 5 · Temperatura alta | 38,9 → 38,0 °C | ATENÇÃO nas duas leituras (motivo: temperatura alta), LED amarelo | `teste5` |
| 6 · Temperatura muito alta | 36,5 → 38,3 → 39,1 °C | NORMAL → ATENÇÃO → CRÍTICO (motivo: temperatura muito alta) | `teste6` |

No documento de entrega (PDF), cada teste tem duas evidências geradas com o simulador do Wokwi:

- **O circuito inteiro com o LED aceso**, no estado final do teste. O teste 1 usa os sensores em repouso e, nos testes 2, 3 e 4, os potenciômetros foram girados no simulador (`FONTE=SENSOR`). Nos testes 5 e 6, os valores foram forçados pelos comandos acima (`FONTE=TESTE`), porque a temperatura não aparece como valor no desenho.
- **A sequência das etapas**, com os três LEDs de cada etapa e as linhas do Monitor Serial com os valores exatos. Nela, o próprio simulador moveu os potenciômetros e os sensores (`FONTE=SENSOR`).

O simulador mostra o aviso "LEDC is not initialized" no primeiro bipe. Ele vem da biblioteca do ESP32 e não afeta o resultado.

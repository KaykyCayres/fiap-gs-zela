# Estatística Aplicada (R)

**Zela** · Global Solution 2026 · CitizenTech

| Integrante | RM |
|---|---|
| Kayky Cayres Vicente da Silva | 575091 |
| Naiara Sousa Soares | 574792 |
| Rafael Medici | 576249 |

## O que é

A Zela é uma pulseira que acompanha a frequência cardíaca (FC), a oxigenação (SpO2) e a temperatura de quem espera atendimento no pronto-socorro. Nesta parte, usamos estatística para entender como esses sinais se comportam em pessoas saudáveis e ver se os limites de alerta da pulseira fazem sentido.

## Arquivos

| Arquivo | O que é |
|---|---|
| `five_vital_signs_of_normal_people.csv` | Dados **reais** do Zenodo: 102 pessoas saudáveis, 9 leituras de cada sinal |
| `medicoes_pulseira_simuladas.csv` | Dados **simulados** pelo grupo a partir dos reais (usados só para comparação) |
| `analise_estatistica.R` | Código da análise |

## O que o código faz

- Tabela de frequências da **FC** (quantitativa discreta) e da **temperatura** (quantitativa contínua)
- Gráfico de barras da FC e histograma da temperatura
- Média, mediana, moda, mínimo, máximo, amplitude, variância, desvio padrão, coeficiente de variação e quartis
- Comparação entre dados reais e simulados
- Teste das regras da pulseira em pessoas saudáveis (alarmes falsos)

## Como rodar

1. Deixe os dois CSV na mesma pasta do `analise_estatistica.R`.
2. No RStudio, instale o pacote da moda (só na primeira vez):
   ```r
   install.packages("DescTools")
   ```
3. Vá em **Session > Set Working Directory > To Source File Location** e rode o script.

## Principais resultados

- **FC:** nenhuma leitura de pessoa saudável chegou a 110 BPM, então o limite de FC da pulseira não gera alarme falso.
- **SpO2 e temperatura:** 5,7% e 7,0% das leituras de pessoas saudáveis disparariam um alerta.
- **Temperatura:** é o sinal com mais ruído; varia mais dentro da mesma pessoa do que entre pessoas.
- **Real × simulado:** a FC simulada é mais alta e mais espalhada que a real, porque inclui perfis de piora. A temperatura simulada tem dispersão parecida com a real (desvio padrão 1,07 e 1,09 °C), mas por outro motivo: na simulada ela vem dos perfis com febre, e na real vem do ruído de medição.
- **Conclusão:** a pulseira deve confirmar a alteração em mais de uma leitura antes de alertar. O protótipo atual da Zela ainda alerta na primeira leitura fora da faixa, então essa confirmação é uma melhoria recomendada que ainda não foi implementada.

O relatório completo, com tabelas, gráficos e interpretações, está no PDF de entrega.

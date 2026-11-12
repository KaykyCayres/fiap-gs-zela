# ==============================================================================
# FIAP - TECNÓLOGO EM INTELIGÊNCIA ARTIFICIAL
# ESTATÍSTICA APLICADA - GLOBAL SOLUTION 2026 (CITIZENTECH)
# TEMA: ZELA - PULSEIRA DE MONITORAMENTO NA ESPERA DO PRONTO-SOCORRO
#
# INTEGRANTES:
#   Kayky Cayres Vicente da Silva - RM 575091
#   Naiara Sousa Soares - RM 574792
#   Rafael Medici - RM 576249
#
# FONTES:
#   five_vital_signs_of_normal_people.csv -> dados REAIS (Zenodo):
#       102 pessoas saudáveis, 9 leituras de cada sinal por pessoa
#   medicoes_pulseira_simuladas.csv -> dados SIMULADOS pelo grupo a partir
#       dos reais (uso autorizado pelo professor, para comparação)
# ==============================================================================

# PACOTE USADO PARA CALCULAR A MODA (rode a instalação só uma vez)
# install.packages("DescTools")
library(DescTools)

#----------------------------------

# IMPORTANDO AS BASES DE DADOS

getwd() # os dois arquivos CSV precisam estar nesta pasta

# check.names = FALSE mantém os nomes originais das colunas (com espaços)
reais     <- read.csv("five_vital_signs_of_normal_people.csv", check.names = FALSE)
simulados <- read.csv("medicoes_pulseira_simuladas.csv")

head(reais[, 1:6]) # primeiras linhas (só as 6 primeiras colunas)
nrow(reais)       # quantidade de pessoas
ncol(reais)       # quantidade de colunas
nrow(simulados)   # quantidade de leituras simuladas

#----------------------------------

# SEPARANDO AS VARIÁVEIS DO TRABALHO
# Quantitativa discreta:  frequência cardíaca (FC, em BPM, número inteiro)
# Quantitativa contínua:  temperatura (°C, com casas decimais)

# Na base real, cada sinal está em 9 colunas (reading 1 a 9).
# Juntamos as 9 colunas em uma matriz (linha = pessoa, coluna = leitura)
fc_matriz   <- as.matrix(reais[, paste("Heart rate reading", 1:9)])
temp_matriz <- as.matrix(reais[, paste("Temperature reading", 1:9)])
spo2_matriz <- as.matrix(reais[, paste("Oxygen saturation reading", 1:9)])

# Transformando cada matriz em um vetor com todas as leituras (102 x 9 = 918)
fc   <- as.vector(fc_matriz)
temp <- as.vector(temp_matriz)
spo2 <- as.vector(spo2_matriz)

# Mesmas variáveis na base simulada
fc_sim   <- simulados$frequencia_cardiaca
temp_sim <- simulados$temperatura

length(fc)       # quantidade de leituras de FC
length(temp)     # quantidade de leituras de temperatura

#----------------------------------

# CONFERINDO A QUALIDADE DOS DADOS REAIS (nada é corrigido, só apontado)

sum(is.na(reais))                  # valores ausentes
sum(duplicated(reais$`Subject ID`)) # pessoas repetidas
sum(spo2 > 100)                    # SpO2 acima de 100% (impossível)
sum(temp < 35)                     # temperaturas abaixo de 35 °C

#----------------------------------

# TABELA DE DISTRIBUIÇÃO DE FREQUÊNCIAS - FC (QUANTITATIVA DISCRETA)
# A FC tem muitos valores diferentes (de 63 a 103),
# então agrupamos em classes de 5 BPM. right = FALSE -> classes [a, b)

faixas_fc <- table(cut(fc, breaks = seq(60, 105, by = 5), right = FALSE))

fa  <- as.vector(faixas_fc)
faa <- cumsum(fa)
fr  <- round((fa / sum(fa)) * 100, 2)
fra <- round((faa / sum(fa)) * 100, 2)

tabela_fc <- data.frame(
  Faixa_de_FC = names(faixas_fc),
  Frequencia_Absoluta = fa,
  Frequencia_Absoluta_Acumulada = faa,
  Frequencia_Relativa = fr,
  Frequencia_Relativa_Acumulada = fra
)

print(tabela_fc)
View(tabela_fc)

#----------------------------------

# TABELA DE DISTRIBUIÇÃO DE FREQUÊNCIAS - TEMPERATURA (QUANTITATIVA CONTÍNUA)
# Número de classes pela regra de Sturges: k = 1 + 3,322 * log10(n)

k <- nclass.Sturges(temp)
k

# Largura de cada classe: amplitude / k, arredondada para cima (0,6 °C)
largura <- ceiling((max(temp) - min(temp)) / k * 10) / 10
largura

faixas_temp <- table(cut(temp, breaks = seq(33, by = largura, length.out = k + 1),
                         right = FALSE, include.lowest = TRUE))

fa  <- as.vector(faixas_temp)
faa <- cumsum(fa)
fr  <- round((fa / sum(fa)) * 100, 2)
fra <- round((faa / sum(fa)) * 100, 2)

tabela_temp <- data.frame(
  Faixa_de_Temperatura = names(faixas_temp),
  Frequencia_Absoluta = fa,
  Frequencia_Absoluta_Acumulada = faa,
  Frequencia_Relativa = fr,
  Frequencia_Relativa_Acumulada = fra
)

print(tabela_temp)
View(tabela_temp)

#----------------------------------

# GRÁFICOS

# GRÁFICO DE BARRAS - FC POR FAIXA
barplot(faixas_fc,
        main = "Frequência Cardíaca de Pessoas Saudáveis (dados reais)",
        xlab = "Frequência cardíaca (BPM)",
        ylab = "Quantidade de leituras",
        col = "#2EC4E6")

# HISTOGRAMA - TEMPERATURA, COM OS LIMITES DE ALERTA DA PULSEIRA
hist(temp,
     breaks = seq(33, by = largura, length.out = k + 1),
     right = FALSE,
     main = "Temperatura de Pessoas Saudáveis (dados reais)",
     xlab = "Temperatura (°C)",
     ylab = "Quantidade de leituras",
     col = "#2EC4E6")

abline(v = 37.8, col = "orange", lwd = 3, lty = 2) # limite de ATENÇÃO
abline(v = 39.0, col = "red",    lwd = 3, lty = 2) # limite de CRÍTICO

legend("topleft",
       legend = c("Limite ATENÇÃO (37,8 °C)", "Limite CRÍTICO (39,0 °C)"),
       col = c("orange", "red"), lwd = 3, lty = 2)

#----------------------------------

# MEDIDAS DE TENDÊNCIA CENTRAL
# Média:   soma dos valores / quantidade de valores
# Mediana: valor central dos dados ordenados
# Moda:    valor que mais se repete

# FC
mean(fc)
median(fc)
Mode(fc)

# Temperatura
mean(temp)
median(temp)
Mode(temp)

#----------------------------------

# MEDIDAS DE DISPERSÃO

# FC
min(fc)
max(fc)
diff(range(fc))              # amplitude = máximo - mínimo
var(fc)                      # variância => não interpretável, pois eleva a grandeza ao quadrado
sd(fc)                       # desvio padrão (mesma unidade dos dados: BPM)
sd(fc) / mean(fc) * 100      # coeficiente de variação (%)

# Temperatura
min(temp)
max(temp)
diff(range(temp))
var(temp)
sd(temp)
sd(temp) / mean(temp) * 100

# Interpretação do CV: até 15% = baixa dispersão | 15% a 30% = média | acima de 30% = alta

#----------------------------------

# MEDIDAS SEPARATRIZES

# QUARTIS - dividem os dados em 4 partes (a mediana é sempre igual ao 2º quartil)
quantile(fc,   probs = c(0.25, 0.50, 0.75))
quantile(temp, probs = c(0.25, 0.50, 0.75))

# SUMÁRIO
summary(fc)
summary(temp)

#----------------------------------

# SIMULAÇÃO DE CENÁRIOS

# CENÁRIO 1: QUANTOS ALARMES FALSOS A PULSEIRA DARIA EM PESSOAS SAUDÁVEIS?
# Regras de ATENÇÃO da pulseira: FC >= 110 ou FC < 50, SpO2 < 95, temperatura >= 37,8

sum(fc >= 110 | fc < 50)              # leituras de FC que disparariam
round(mean(spo2 < 95) * 100, 1)       # % de leituras de SpO2 abaixo de 95
round(mean(temp >= 37.8) * 100, 1)    # % de leituras de temperatura em 37,8 ou mais
round(mean(temp >= 39) * 100, 1)      # % em 39 ou mais (CRÍTICO)

alarme <- fc >= 110 | fc < 50 | spo2 < 95 | temp >= 37.8
round(mean(alarme) * 100, 1)          # % de leituras com algum alarme falso

# CENÁRIO 2: O SINAL VARIA MAIS DENTRO DA PESSOA OU ENTRE PESSOAS?
# apply(matriz, 1, sd) calcula o desvio padrão de cada linha (de cada pessoa)

mean(apply(fc_matriz, 1, sd))     # FC: variação média dentro da mesma pessoa
sd(rowMeans(fc_matriz))           # FC: variação entre as médias das pessoas

mean(apply(temp_matriz, 1, sd))   # temperatura: dentro da mesma pessoa
sd(rowMeans(temp_matriz))         # temperatura: entre pessoas

# CENÁRIO 3: DADOS REAIS x DADOS SIMULADOS
comparacao <- data.frame(
  Medida = c("Média", "Mediana", "Mínimo", "Máximo", "Desvio padrão", "CV (%)", "Q1", "Q3"),
  FC_real = round(c(mean(fc), median(fc), min(fc), max(fc), sd(fc),
                    sd(fc) / mean(fc) * 100, quantile(fc, c(0.25, 0.75))), 2),
  FC_simulada = round(c(mean(fc_sim), median(fc_sim), min(fc_sim), max(fc_sim), sd(fc_sim),
                        sd(fc_sim) / mean(fc_sim) * 100, quantile(fc_sim, c(0.25, 0.75))), 2),
  Temp_real = round(c(mean(temp), median(temp), min(temp), max(temp), sd(temp),
                      sd(temp) / mean(temp) * 100, quantile(temp, c(0.25, 0.75))), 2),
  Temp_simulada = round(c(mean(temp_sim), median(temp_sim), min(temp_sim), max(temp_sim), sd(temp_sim),
                          sd(temp_sim) / mean(temp_sim) * 100, quantile(temp_sim, c(0.25, 0.75))), 2)
)
print(comparacao)

Mode(fc_sim)
Mode(temp_sim)

# BOXPLOT - COMPARAÇÃO REAL x SIMULADO
par(mfrow = c(1, 2))   # dois gráficos lado a lado

boxplot(fc, fc_sim,
        names = c("Real", "Simulado"),
        main = "FC: Real x Simulado",
        ylab = "Frequência cardíaca (BPM)",
        col = c("#2EC4E6", "#E6F7FB"))
abline(h = c(110, 130), col = c("orange", "red"), lty = 2, lwd = 2)

boxplot(temp, temp_sim,
        names = c("Real", "Simulado"),
        main = "Temperatura: Real x Simulado",
        ylab = "Temperatura (°C)",
        col = c("#2EC4E6", "#E6F7FB"))
abline(h = c(37.8, 39), col = c("orange", "red"), lty = 2, lwd = 2)

par(mfrow = c(1, 1))   # volta ao normal


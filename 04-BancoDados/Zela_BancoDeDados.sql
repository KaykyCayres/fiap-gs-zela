-- =====================================================================
-- ZELA - Pulseira de monitoramento na espera do pronto-socorro
-- Global Solution 2026.2 (CitizenTech) - Cognitive Data Science
-- Integrantes: Naiara Sousa Soares (RM 574792), Rafael Medici (RM 576249),
--              Kayky Cayres Vicente da Silva (RM 575091)
--
-- Versao simplificada do modelo, usada pelo prototipo (API C# e painel) e
-- pela AWS (RDS e Lambda). Adaptacao do case "Fazendas inteligentes":
--   fazenda        -> Unidade (pronto-socorro / UPA)
--   sensor         -> Sensor de uma pulseira (FC, SpO2, temperatura)
--   medicao        -> Medicao (uma linha por sensor)
--   limite minimo  -> limites de atencao e critico em TipoMedicao
--   historico      -> Alerta (preenchida pela trigger)
--
-- Valores das medicoes: dados SIMULADOS a partir do dataset publico do
-- Zenodo "Five vital signs of normal people". Limites experimentais, sem
-- valor clinico. O codigo do paciente (PAC-0001...) e gerado a partir do
-- idMonitoramento: nenhum nome ou documento e guardado (LGPD).
--
-- ATENCAO: o DROP DATABASE abaixo e so para a entrega. No RDS do prototipo
-- em uso, rode a partir do CREATE DATABASE (sem o DROP).
-- =====================================================================

DROP DATABASE IF EXISTS zela;
CREATE DATABASE zela;
USE zela;

-- -----------------------------
-- 1. Tabelas (DDL)
-- -----------------------------
-- CHECK: o banco so aceita valores validos (ex.: status ATIVO, MANUTENCAO ou INATIVO)
-- UNIQUE: impede repeticao (mesma leitura duas vezes / mais de um alerta por medicao)
CREATE TABLE Unidade (
    idUnidade   INT AUTO_INCREMENT PRIMARY KEY,
    nome        VARCHAR(80) NOT NULL
);

-- Cada tipo de sinal tem seus limites, em dois niveis (atencao e critico).
-- Coluna NULL = nao existe limite daquele lado (ex.: FC nao tem critico inferior).
-- Regra: valor >= limite superior ou valor < limite inferior.
CREATE TABLE TipoMedicao (
    idTipoMedicao    INT AUTO_INCREMENT PRIMARY KEY,
    nome             VARCHAR(40)  NOT NULL UNIQUE,
    unidadeMedida    VARCHAR(10)  NOT NULL,
    atencaoInferior  DECIMAL(6,2) NULL,
    atencaoSuperior  DECIMAL(6,2) NULL,
    criticoInferior  DECIMAL(6,2) NULL,
    criticoSuperior  DECIMAL(6,2) NULL
);

CREATE TABLE Pulseira (
    idPulseira  INT AUTO_INCREMENT PRIMARY KEY,
    codigo      VARCHAR(20) NOT NULL UNIQUE,
    status      VARCHAR(12) NOT NULL DEFAULT 'ATIVA'
                CHECK (status IN ('ATIVA','MANUTENCAO','INATIVA')),
    idUnidade   INT NOT NULL,
    FOREIGN KEY (idUnidade) REFERENCES Unidade(idUnidade)
);

CREATE TABLE Sensor (
    idSensor       INT AUTO_INCREMENT PRIMARY KEY,
    codigo         VARCHAR(30) NOT NULL UNIQUE,
    modelo         VARCHAR(30) NOT NULL,
    status         VARCHAR(12) NOT NULL DEFAULT 'ATIVO'
                   CHECK (status IN ('ATIVO','MANUTENCAO','INATIVO')),
    idPulseira     INT NOT NULL,
    idTipoMedicao  INT NOT NULL,
    FOREIGN KEY (idPulseira)    REFERENCES Pulseira(idPulseira),
    FOREIGN KEY (idTipoMedicao) REFERENCES TipoMedicao(idTipoMedicao)
);

-- Um monitoramento liga uma pulseira a um paciente durante a espera.
-- dtFim vazio = monitoramento ativo. A API garante que cada pulseira tenha
-- no maximo um monitoramento ativo.
CREATE TABLE Monitoramento (
    idMonitoramento  INT AUTO_INCREMENT PRIMARY KEY,
    idPulseira       INT NOT NULL,
    dtInicio         DATETIME NOT NULL,
    dtFim            DATETIME NULL,
    CHECK (dtFim IS NULL OR dtFim >= dtInicio),
    FOREIGN KEY (idPulseira) REFERENCES Pulseira(idPulseira)
);

CREATE TABLE Medicao (
    idMedicao        INT AUTO_INCREMENT PRIMARY KEY,
    idSensor         INT NOT NULL,
    idMonitoramento  INT NOT NULL,
    valor            DECIMAL(6,2) NOT NULL,
    dtMedicao        DATETIME(3) NOT NULL,
    origemDado       VARCHAR(10) NOT NULL DEFAULT 'SIMULADO'
                     CHECK (origemDado IN ('REAL','SIMULADO','DERIVADO')),
    UNIQUE (idSensor, dtMedicao),          -- evita gravar a mesma leitura duas vezes
    FOREIGN KEY (idSensor)        REFERENCES Sensor(idSensor),
    FOREIGN KEY (idMonitoramento) REFERENCES Monitoramento(idMonitoramento)
);

-- Historico de alertas: guarda uma "foto" da unidade, do sensor, do valor e do
-- limite cruzado no momento do alerta (como na tabela de auditoria vista em aula).
-- dtCiente fica vazio ate a enfermagem clicar em "Ciente" no painel.
CREATE TABLE Alerta (
    idAlerta   INT AUTO_INCREMENT PRIMARY KEY,
    idMedicao  INT NOT NULL UNIQUE,
    idUnidade  INT NOT NULL,
    idSensor   INT NOT NULL,
    valor      DECIMAL(6,2) NOT NULL,
    limite     DECIMAL(6,2) NOT NULL,
    nivel      VARCHAR(7) NOT NULL CHECK (nivel IN ('ATENCAO','CRITICO')),
    dtAlerta   DATETIME(3) NOT NULL,
    dtCiente   DATETIME NULL,
    FOREIGN KEY (idMedicao) REFERENCES Medicao(idMedicao),
    FOREIGN KEY (idUnidade) REFERENCES Unidade(idUnidade),
    FOREIGN KEY (idSensor)  REFERENCES Sensor(idSensor)
);

-- -----------------------------
-- 2. Trigger: AFTER INSERT na Medicao
-- -----------------------------
-- Compara a medicao com os limites do tipo do sensor (TipoMedicao). Se passar do
-- limite, grava um alerta, desde que o monitoramento ainda nao tenha um alerta
-- do mesmo nivel (ou CRITICO). Assim o painel nao enche de alertas repetidos
-- e um paciente que piora de ATENCAO para CRITICO gera um novo alerta.
DELIMITER $$
CREATE TRIGGER trg_alerta_medicao
AFTER INSERT ON Medicao
FOR EACH ROW
BEGIN
    DECLARE v_idUnidade INT;
    DECLARE v_atInf   DECIMAL(6,2);
    DECLARE v_atSup   DECIMAL(6,2);
    DECLARE v_crInf   DECIMAL(6,2);
    DECLARE v_crSup   DECIMAL(6,2);
    DECLARE v_nivel   VARCHAR(7) DEFAULT NULL;
    DECLARE v_limite  DECIMAL(6,2);
    DECLARE v_repetido INT DEFAULT 0;

    SELECT P.idUnidade, T.atencaoInferior, T.atencaoSuperior,
           T.criticoInferior, T.criticoSuperior
      INTO v_idUnidade, v_atInf, v_atSup, v_crInf, v_crSup
      FROM Sensor S
     INNER JOIN Pulseira P    ON S.idPulseira = P.idPulseira
     INNER JOIN TipoMedicao T ON S.idTipoMedicao = T.idTipoMedicao
     WHERE S.idSensor = NEW.idSensor;

    -- O caso mais grave e testado primeiro. Comparar com NULL nao e verdadeiro,
    -- entao um limite que nao existe e simplesmente ignorado.
    IF NEW.valor >= v_crSup THEN
        SET v_nivel = 'CRITICO', v_limite = v_crSup;
    ELSEIF NEW.valor < v_crInf THEN
        SET v_nivel = 'CRITICO', v_limite = v_crInf;
    ELSEIF NEW.valor >= v_atSup THEN
        SET v_nivel = 'ATENCAO', v_limite = v_atSup;
    ELSEIF NEW.valor < v_atInf THEN
        SET v_nivel = 'ATENCAO', v_limite = v_atInf;
    END IF;

    IF v_nivel IS NOT NULL THEN
        SELECT COUNT(*) INTO v_repetido
          FROM Alerta A
         INNER JOIN Medicao M ON M.idMedicao = A.idMedicao
         WHERE M.idMonitoramento = NEW.idMonitoramento
           AND (A.nivel = v_nivel OR A.nivel = 'CRITICO');

        IF v_repetido = 0 THEN
            INSERT INTO Alerta (idMedicao, idUnidade, idSensor, valor, limite, nivel, dtAlerta)
            VALUES (NEW.idMedicao, v_idUnidade, NEW.idSensor, NEW.valor,
                    v_limite, v_nivel, NEW.dtMedicao);
        END IF;
    END IF;
END $$
DELIMITER ;

-- -----------------------------
-- 3. Dados (DML)
-- -----------------------------
INSERT INTO Unidade (nome) VALUES
('Pronto-Socorro Central'),
('UPA Vila Mariana'),
('Pronto-Socorro Messejana');

-- Limites de DEMONSTRACAO combinados pelo grupo (nao sao criterio clinico).
-- Sao os mesmos do firmware da pulseira e do programa em Python.
INSERT INTO TipoMedicao (nome, unidadeMedida, atencaoInferior, atencaoSuperior, criticoInferior, criticoSuperior) VALUES
('Frequencia cardiaca',   'bpm', 50.00, 110.00, NULL,  130.00),  -- atencao < 50 ou >= 110; critico >= 130
('Saturacao de oxigenio', '%',   95.00, NULL,   90.00, NULL),    -- atencao < 95; critico < 90
('Temperatura corporal',  'C',   NULL,  37.80,  NULL,  39.00);   -- atencao >= 37,8; critico >= 39,0

INSERT INTO Pulseira (codigo, status, idUnidade) VALUES
('ESP32-0001','ATIVA',1), ('ESP32-0002','ATIVA',1),
('ESP32-0003','ATIVA',2), ('ESP32-0004','ATIVA',2),
('ESP32-0005','ATIVA',3), ('ESP32-0006','ATIVA',3),
('ESP32-0007','MANUTENCAO',3);

-- 3 sensores por pulseira, sempre na ordem FC, SpO2, temperatura
-- (idSensor = 3 x (idPulseira - 1) + 1 ... 3 x idPulseira)
INSERT INTO Sensor (codigo, modelo, status, idPulseira, idTipoMedicao) VALUES
('ESP32-0001-FC','MAX30102','ATIVO',1,1),
('ESP32-0001-SPO2','MAX30102','ATIVO',1,2),
('ESP32-0001-TEMP','MAX30205','ATIVO',1,3),
('ESP32-0002-FC','MAX30102','ATIVO',2,1),
('ESP32-0002-SPO2','MAX30102','ATIVO',2,2),
('ESP32-0002-TEMP','MAX30205','ATIVO',2,3),
('ESP32-0003-FC','MAX30102','ATIVO',3,1),
('ESP32-0003-SPO2','MAX30102','ATIVO',3,2),
('ESP32-0003-TEMP','MAX30205','ATIVO',3,3),
('ESP32-0004-FC','MAX30102','ATIVO',4,1),
('ESP32-0004-SPO2','MAX30102','ATIVO',4,2),
('ESP32-0004-TEMP','MAX30205','ATIVO',4,3),
('ESP32-0005-FC','MAX30102','ATIVO',5,1),
('ESP32-0005-SPO2','MAX30102','ATIVO',5,2),
('ESP32-0005-TEMP','MAX30205','ATIVO',5,3),
('ESP32-0006-FC','MAX30102','ATIVO',6,1),
('ESP32-0006-SPO2','MAX30102','ATIVO',6,2),
('ESP32-0006-TEMP','MAX30205','ATIVO',6,3),
('ESP32-0007-FC','MAX30102','MANUTENCAO',7,1),
('ESP32-0007-SPO2','MAX30102','MANUTENCAO',7,2),
('ESP32-0007-TEMP','MAX30205','INATIVO',7,3);

-- Monitoramentos de exemplo, todos ja ENCERRADOS (dtFim preenchido): assim a
-- carga de dados nao aparece como paciente ativo no painel.
-- Codigo do paciente = 'PAC-' + idMonitoramento com 4 digitos (PAC-0001 ...).
INSERT INTO Monitoramento (idPulseira, dtInicio, dtFim) VALUES
(1,'2026-11-10 14:00:00','2026-11-10 17:00:00'),
(2,'2026-11-10 14:05:00','2026-11-10 17:00:00'),
(3,'2026-11-10 14:10:00','2026-11-10 17:00:00'),
(4,'2026-11-10 14:15:00','2026-11-10 17:00:00'),
(5,'2026-11-10 14:20:00','2026-11-10 17:00:00'),
(6,'2026-11-10 14:25:00','2026-11-10 17:00:00');

-- Medicoes: leitura inicial e leitura de pico de cada paciente, tiradas da
-- planilha medicoes_pulseira_simuladas.csv (36 medicoes = 6 pacientes x 2 leituras x 3 sinais)
INSERT INTO Medicao (idSensor, idMonitoramento, valor, dtMedicao, origemDado) VALUES
(1,1,74.00,'2026-11-10 14:00:00','SIMULADO'),
(2,1,97.10,'2026-11-10 14:00:00','SIMULADO'),
(3,1,35.87,'2026-11-10 14:00:00','SIMULADO'),
(1,1,72.00,'2026-11-10 15:10:00','SIMULADO'),
(2,1,98.50,'2026-11-10 15:10:00','SIMULADO'),
(3,1,35.97,'2026-11-10 15:10:00','SIMULADO'),
(4,2,69.00,'2026-11-10 14:05:00','SIMULADO'),
(5,2,99.30,'2026-11-10 14:05:00','SIMULADO'),
(6,2,35.57,'2026-11-10 14:05:00','SIMULADO'),
(4,2,106.00,'2026-11-10 15:15:00','SIMULADO'),
(5,2,98.20,'2026-11-10 15:15:00','SIMULADO'),
(6,2,37.41,'2026-11-10 15:15:00','SIMULADO'),
(7,3,90.00,'2026-11-10 14:10:00','SIMULADO'),
(8,3,96.70,'2026-11-10 14:10:00','SIMULADO'),
(9,3,35.25,'2026-11-10 14:10:00','SIMULADO'),
(7,3,106.00,'2026-11-10 15:20:00','SIMULADO'),
(8,3,88.00,'2026-11-10 15:20:00','SIMULADO'),
(9,3,35.32,'2026-11-10 15:20:00','SIMULADO'),
(10,4,86.00,'2026-11-10 14:15:00','SIMULADO'),
(11,4,95.40,'2026-11-10 14:15:00','SIMULADO'),
(12,4,36.03,'2026-11-10 14:15:00','SIMULADO'),
(10,4,136.00,'2026-11-10 15:25:00','SIMULADO'),
(11,4,84.80,'2026-11-10 15:25:00','SIMULADO'),
(12,4,39.04,'2026-11-10 15:25:00','SIMULADO'),
(13,5,94.00,'2026-11-10 14:20:00','SIMULADO'),
(14,5,96.40,'2026-11-10 14:20:00','SIMULADO'),
(15,5,35.25,'2026-11-10 14:20:00','SIMULADO'),
(13,5,131.00,'2026-11-10 14:54:00','SIMULADO'),
(14,5,88.50,'2026-11-10 14:54:00','SIMULADO'),
(15,5,35.85,'2026-11-10 14:54:00','SIMULADO'),
(16,6,77.00,'2026-11-10 14:25:00','SIMULADO'),
(17,6,98.10,'2026-11-10 14:25:00','SIMULADO'),
(18,6,36.18,'2026-11-10 14:25:00','SIMULADO'),
(16,6,74.00,'2026-11-10 15:35:00','SIMULADO'),
(17,6,99.80,'2026-11-10 15:35:00','SIMULADO'),
(18,6,36.12,'2026-11-10 15:35:00','SIMULADO');

-- -----------------------------
-- 4. Consultas
-- -----------------------------
-- DISTINCT: conta cada sensor uma vez, mesmo que ele tenha varias medicoes
-- AVG: media das medicoes por unidade e por sinal (nao da para misturar bpm, % e C)

-- 4.1 Total de sensores por unidade
SELECT U.nome AS unidade, COUNT(S.idSensor) AS totalSensores
  FROM Unidade U
 INNER JOIN Pulseira P ON P.idUnidade = U.idUnidade
 INNER JOIN Sensor S   ON S.idPulseira = P.idPulseira
 GROUP BY U.idUnidade, U.nome
 ORDER BY U.idUnidade;

-- 4.2 Media das medicoes por unidade e por sinal
SELECT U.nome                      AS unidade,
       T.nome                      AS sinal,
       COUNT(DISTINCT S.idSensor)  AS totalSensores,
       ROUND(AVG(M.valor), 2)      AS mediaMedicoes,
       T.unidadeMedida             AS medida
  FROM Unidade U
 INNER JOIN Pulseira P    ON P.idUnidade = U.idUnidade
 INNER JOIN Sensor S      ON S.idPulseira = P.idPulseira
 INNER JOIN TipoMedicao T ON T.idTipoMedicao = S.idTipoMedicao
  LEFT JOIN Medicao M     ON M.idSensor = S.idSensor
 GROUP BY U.idUnidade, U.nome, T.idTipoMedicao, T.nome, T.unidadeMedida
 ORDER BY U.idUnidade, T.idTipoMedicao;

-- -----------------------------
-- 5. Function: menor valor medido por um sensor
-- -----------------------------
DELIMITER $$
CREATE FUNCTION fn_valor_minimo_sensor(p_idSensor INT)
RETURNS DECIMAL(6,2)
DETERMINISTIC
BEGIN
    DECLARE v_minimo DECIMAL(6,2) DEFAULT 0;
    SELECT MIN(valor) INTO v_minimo
      FROM Medicao
     WHERE idSensor = p_idSensor;
    RETURN v_minimo;
END $$
DELIMITER ;

-- Sensor 8 = SpO2 da pulseira 3 (menor valor: 88.00)
SELECT fn_valor_minimo_sensor(8) AS spo2MinimaSensor8;

-- -----------------------------
-- 6. Procedure: nome da unidade, tipos de sensores e qualidade (status)
-- -----------------------------
DELIMITER $$
CREATE PROCEDURE sp_relatorio_unidade(IN p_idUnidade INT)
BEGIN
    SELECT DISTINCT U.nome AS unidade, T.nome AS tipoSensor, S.modelo
      FROM Unidade U
     INNER JOIN Pulseira P    ON P.idUnidade = U.idUnidade
     INNER JOIN Sensor S      ON S.idPulseira = P.idPulseira
     INNER JOIN TipoMedicao T ON T.idTipoMedicao = S.idTipoMedicao
     WHERE U.idUnidade = p_idUnidade
     ORDER BY T.nome;

    SELECT S.status AS qualidade, COUNT(*) AS quantidade
      FROM Sensor S
     INNER JOIN Pulseira P ON P.idPulseira = S.idPulseira
     WHERE P.idUnidade = p_idUnidade
     GROUP BY S.status;
END $$
DELIMITER ;

CALL sp_relatorio_unidade(1);
CALL sp_relatorio_unidade(2);
CALL sp_relatorio_unidade(3);

-- -----------------------------
-- 7. Evidencias da trigger
-- -----------------------------
SHOW TRIGGERS;

-- Alertas gerados pela carga inicial (esperado: 3, um por monitoramento
-- 3, 4 e 5; no 4 e no 5 o 2o sinal critico nao repete o alerta)
SELECT A.idAlerta, U.nome AS unidade, S.codigo AS sensor, A.valor,
       A.limite, A.nivel, A.dtAlerta
  FROM Alerta A
 INNER JOIN Unidade U ON U.idUnidade = A.idUnidade
 INNER JOIN Sensor S  ON S.idSensor  = A.idSensor
 ORDER BY A.idAlerta;

-- Teste 1: temperatura de 39,2 C (acima de 39,0, gera alerta CRITICO)
-- e batimento de 82 bpm (normal, nao gera alerta)
INSERT INTO Medicao (idSensor, idMonitoramento, valor, dtMedicao, origemDado)
VALUES (18, 6, 39.20, '2026-11-10 15:30:00', 'SIMULADO'),
       (13, 5, 82.00, '2026-11-10 15:31:00', 'SIMULADO');

-- Teste 2: sem repeticao. Temperatura de 38,0 C gera ATENCAO; 38,2 C logo
-- depois nao gera outro alerta; SpO2 de 85% (CRITICO) gera um novo
INSERT INTO Medicao (idSensor, idMonitoramento, valor, dtMedicao, origemDado)
VALUES (6, 2, 38.00, '2026-11-10 15:40:00', 'SIMULADO'),
       (6, 2, 38.20, '2026-11-10 15:41:00', 'SIMULADO'),
       (5, 2, 85.00, '2026-11-10 15:42:00', 'SIMULADO');

SELECT A.idAlerta, U.nome AS unidade, S.codigo AS sensor, A.valor,
       A.limite, A.nivel, A.dtAlerta
  FROM Alerta A
 INNER JOIN Unidade U ON U.idUnidade = A.idUnidade
 INNER JOIN Sensor S  ON S.idSensor  = A.idSensor
 ORDER BY A.idAlerta DESC
 LIMIT 3;
-- Esperado: SpO2 85% (CRITICO), temperatura 38,0 (ATENCAO) e temperatura 39,2 (CRITICO)

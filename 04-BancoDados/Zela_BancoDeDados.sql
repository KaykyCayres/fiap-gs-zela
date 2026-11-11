-- =====================================================================
-- ZELA - Pulseira de monitoramento na espera do pronto-socorro
-- Global Solution 2026.2 (CitizenTech) - Cognitive Data Science
-- Integrantes: Naiara Sousa Soares (RM 574792), Rafael Medici (RM 576249),
--              Kayky Cayres Vicente da Silva (RM 575091)
-- Adaptacao do case "Fazendas inteligentes":
--   local (fazenda)  -> Unidade (pronto-socorro / UPA)
--   sensor           -> Sensor de uma pulseira (FC, SpO2, temperatura)
--   medicao          -> Medicao
--   limite           -> RegraAlerta (limites de DEMONSTRACAO, sem valor clinico)
--   historico        -> Alerta (preenchida pelo trigger)
-- Valores das medicoes: dados SIMULADOS a partir do dataset publico do
-- Zenodo "Five vital signs of normal people" (programa do grupo).
-- =====================================================================

DROP DATABASE IF EXISTS zela;
CREATE DATABASE zela;
USE zela;

-- -----------------------------
-- 1. Tabelas (DDL)
-- -----------------------------
CREATE TABLE Unidade (
    idUnidade   INT AUTO_INCREMENT PRIMARY KEY,
    nome        VARCHAR(80)  NOT NULL,
    tipo        VARCHAR(10)  NOT NULL CHECK (tipo IN ('PS','UPA')),
    cidade      VARCHAR(50)  NOT NULL,
    uf          CHAR(2)      NOT NULL
);

CREATE TABLE TipoMedicao (
    idTipoMedicao  INT AUTO_INCREMENT PRIMARY KEY,
    nome           VARCHAR(40) NOT NULL UNIQUE,
    unidadeMedida  VARCHAR(10) NOT NULL
);

CREATE TABLE RegraAlerta (
    idRegra         INT AUTO_INCREMENT PRIMARY KEY,
    idTipoMedicao   INT NOT NULL UNIQUE,
    limiteInferior  DECIMAL(6,2) NOT NULL,
    limiteSuperior  DECIMAL(6,2) NOT NULL,
    CHECK (limiteInferior < limiteSuperior),
    FOREIGN KEY (idTipoMedicao) REFERENCES TipoMedicao(idTipoMedicao)
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

CREATE TABLE Paciente (
    idPaciente  INT AUTO_INCREMENT PRIMARY KEY,
    pseudonimo  VARCHAR(12) NOT NULL UNIQUE   -- sem nome ou documento (LGPD)
);

CREATE TABLE Atendimento (
    idAtendimento  INT AUTO_INCREMENT PRIMARY KEY,
    idPaciente     INT NOT NULL,
    idPulseira     INT NOT NULL,   -- a unidade vem pela pulseira (3FN)
    corTriagem     VARCHAR(10) NOT NULL
                   CHECK (corTriagem IN ('VERMELHO','LARANJA','AMARELO','VERDE','AZUL')),
    dtEntrada      DATETIME NOT NULL,
    FOREIGN KEY (idPaciente) REFERENCES Paciente(idPaciente),
    FOREIGN KEY (idPulseira) REFERENCES Pulseira(idPulseira)
);

CREATE TABLE Medicao (
    idMedicao      INT AUTO_INCREMENT PRIMARY KEY,
    idSensor       INT NOT NULL,
    idAtendimento  INT NOT NULL,
    valor          DECIMAL(6,2) NOT NULL,
    dtMedicao      DATETIME NOT NULL,
    origemDado     VARCHAR(10) NOT NULL DEFAULT 'SIMULADO'
                   CHECK (origemDado IN ('REAL','SIMULADO','DERIVADO')),
    UNIQUE (idSensor, dtMedicao),             -- evita importar a mesma leitura duas vezes
    FOREIGN KEY (idSensor)      REFERENCES Sensor(idSensor),
    FOREIGN KEY (idAtendimento) REFERENCES Atendimento(idAtendimento)
);

-- Historico de alertas: guarda uma "foto" do valor e dos limites no momento
-- do alerta (mesma ideia da tabela de auditoria vista em aula).
CREATE TABLE Alerta (
    idAlerta        INT AUTO_INCREMENT PRIMARY KEY,
    idMedicao       INT NOT NULL UNIQUE,
    idUnidade       INT NOT NULL,
    idSensor        INT NOT NULL,
    valor           DECIMAL(6,2) NOT NULL,
    limiteInferior  DECIMAL(6,2) NOT NULL,
    limiteSuperior  DECIMAL(6,2) NOT NULL,
    dtAlerta        DATETIME NOT NULL,
    FOREIGN KEY (idMedicao) REFERENCES Medicao(idMedicao),
    FOREIGN KEY (idUnidade) REFERENCES Unidade(idUnidade),
    FOREIGN KEY (idSensor)  REFERENCES Sensor(idSensor)
);

-- -----------------------------
-- 2. Trigger: AFTER INSERT na Medicao
-- -----------------------------
DELIMITER $$
CREATE TRIGGER trg_alerta_medicao
AFTER INSERT ON Medicao
FOR EACH ROW
BEGIN
    DECLARE v_idUnidade INT DEFAULT 0;
    DECLARE v_inferior  DECIMAL(6,2);
    DECLARE v_superior  DECIMAL(6,2);

    SELECT P.idUnidade, R.limiteInferior, R.limiteSuperior
      INTO v_idUnidade, v_inferior, v_superior
      FROM Sensor S
     INNER JOIN Pulseira P    ON S.idPulseira = P.idPulseira
     INNER JOIN RegraAlerta R ON S.idTipoMedicao = R.idTipoMedicao
     WHERE S.idSensor = NEW.idSensor;

    IF NEW.valor < v_inferior OR NEW.valor > v_superior THEN
        INSERT INTO Alerta
           SET idMedicao = NEW.idMedicao, idUnidade = v_idUnidade,
               idSensor = NEW.idSensor, valor = NEW.valor,
               limiteInferior = v_inferior, limiteSuperior = v_superior,
               dtAlerta = NEW.dtMedicao;
    END IF;
END $$
DELIMITER ;

-- -----------------------------
-- 3. Dados (DML)
-- -----------------------------
INSERT INTO Unidade (nome, tipo, cidade, uf) VALUES
('Pronto-Socorro Central',      'PS',  'Sao Paulo', 'SP'),
('UPA Vila Mariana',            'UPA', 'Sao Paulo', 'SP'),
('Pronto-Socorro Messejana',    'PS',  'Fortaleza', 'CE');

INSERT INTO TipoMedicao (nome, unidadeMedida) VALUES
('Frequencia cardiaca', 'bpm'),
('Saturacao de oxigenio', '%'),
('Temperatura corporal', 'C');

-- Limites de DEMONSTRACAO combinados pelo grupo (nao sao criterio clinico)
INSERT INTO RegraAlerta (idTipoMedicao, limiteInferior, limiteSuperior) VALUES
(1, 40.00, 120.00),
(2, 90.00, 100.00),
(3, 34.00, 38.50);

INSERT INTO Pulseira (codigo, status, idUnidade) VALUES
('ESP32-0001','ATIVA',1), ('ESP32-0002','ATIVA',1),
('ESP32-0003','ATIVA',2), ('ESP32-0004','ATIVA',2),
('ESP32-0005','ATIVA',3), ('ESP32-0006','ATIVA',3),
('ESP32-0007','MANUTENCAO',3);

INSERT INTO Sensor (codigo, modelo, status, idPulseira, idTipoMedicao) VALUES
('ESP32-0001-FC','MAX30102','ATIVO',1,1),
('ESP32-0001-SPO2','MAX30102','ATIVO',1,2),
('ESP32-0001-TEMP','DS18B20','ATIVO',1,3),
('ESP32-0002-FC','MAX30102','ATIVO',2,1),
('ESP32-0002-SPO2','MAX30102','ATIVO',2,2),
('ESP32-0002-TEMP','DS18B20','ATIVO',2,3),
('ESP32-0003-FC','MAX30102','ATIVO',3,1),
('ESP32-0003-SPO2','MAX30102','ATIVO',3,2),
('ESP32-0003-TEMP','DS18B20','ATIVO',3,3),
('ESP32-0004-FC','MAX30102','ATIVO',4,1),
('ESP32-0004-SPO2','MAX30102','ATIVO',4,2),
('ESP32-0004-TEMP','DS18B20','ATIVO',4,3),
('ESP32-0005-FC','MAX30102','ATIVO',5,1),
('ESP32-0005-SPO2','MAX30102','ATIVO',5,2),
('ESP32-0005-TEMP','DS18B20','ATIVO',5,3),
('ESP32-0006-FC','MAX30102','ATIVO',6,1),
('ESP32-0006-SPO2','MAX30102','ATIVO',6,2),
('ESP32-0006-TEMP','DS18B20','ATIVO',6,3),
('ESP32-0007-FC','MAX30102','MANUTENCAO',7,1),
('ESP32-0007-SPO2','MAX30102','MANUTENCAO',7,2),
('ESP32-0007-TEMP','DS18B20','INATIVO',7,3);

INSERT INTO Paciente (pseudonimo) VALUES
('PAC-0001'),
('PAC-0002'),
('PAC-0003'),
('PAC-0004'),
('PAC-0005'),
('PAC-0006');

INSERT INTO Atendimento (idPaciente, idPulseira, corTriagem, dtEntrada) VALUES
(1,1,'AMARELO','2026-11-10 14:00:00'),
(2,2,'AMARELO','2026-11-10 14:05:00'),
(3,3,'AMARELO','2026-11-10 14:10:00'),
(4,4,'LARANJA','2026-11-10 14:15:00'),
(5,5,'AMARELO','2026-11-10 14:20:00'),
(6,6,'VERDE','2026-11-10 14:25:00');

-- Medicoes: leitura inicial e leitura de pico de cada paciente, tiradas da
-- planilha medicoes_pulseira_simuladas.csv (36 medicoes = 6 pacientes x 2 leituras x 3 sinais)
INSERT INTO Medicao (idSensor, idAtendimento, valor, dtMedicao, origemDado) VALUES
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
(6,2,35.81,'2026-11-10 15:15:00','SIMULADO'),
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
(12,4,37.24,'2026-11-10 15:25:00','SIMULADO'),
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
-- 4. Consulta: total de sensores e media das medicoes por unidade e sinal
-- -----------------------------
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
-- 7. Evidencias do trigger
-- -----------------------------
SHOW TRIGGERS;

SELECT A.idAlerta, U.nome AS unidade, S.codigo AS sensor, A.valor,
       A.limiteInferior, A.limiteSuperior, A.dtAlerta
  FROM Alerta A
 INNER JOIN Unidade U ON U.idUnidade = A.idUnidade
 INNER JOIN Sensor S  ON S.idSensor  = A.idSensor
 ORDER BY A.dtAlerta, A.idAlerta;

-- Teste: temperatura de 39,2 C (acima do limite, gera alerta)
-- e batimento de 82 bpm (normal, nao gera alerta)
INSERT INTO Medicao (idSensor, idAtendimento, valor, dtMedicao, origemDado)
VALUES (18, 6, 39.20, '2026-11-10 15:30:00', 'SIMULADO'),
       (13, 5, 82.00, '2026-11-10 15:31:00', 'SIMULADO');

SELECT A.idAlerta, U.nome AS unidade, S.codigo AS sensor, A.valor,
       A.limiteInferior, A.limiteSuperior, A.dtAlerta
  FROM Alerta A
 INNER JOIN Unidade U ON U.idUnidade = A.idUnidade
 INNER JOIN Sensor S  ON S.idSensor  = A.idSensor
 ORDER BY A.idAlerta DESC
 LIMIT 3;


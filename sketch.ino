/*
  Zela - Pulseira de monitoramento na espera do pronto-socorro
  Global Solution 2026 - AI Computer Systems & Sensors (AICSS)
  Kayky Cayres Vicente da Silva (RM 575091)
  Naiara Sousa Soares (RM 574792)
  Rafael Medici (RM 576249)

  O que e REAL no Wokwi (sensor simulado pelo Wokwi):
    - Temperatura: DS18B20 (GPIO 4)
    - Movimento:   MPU6050 (SDA 21 / SCL 22)
  O que e SIMULADO por nos:
    - FC e SpO2: potenciometros (GPIO 34 e 35), no lugar do MAX30102,
      que nao existe no Wokwi.

  ATENCAO: regras experimentais, so para fins academicos.
  O dispositivo NAO faz diagnostico e NAO substitui a equipe de saude.
*/

#include <OneWire.h>
#include <DallasTemperature.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

// ---------------- Pinos ----------------
#define PINO_TEMP     4
#define PINO_POT_FC   34
#define PINO_POT_SPO2 35
#define LED_VERDE     25
#define LED_AMARELO   26
#define LED_VERMELHO  27
#define PINO_BUZZER   14

// ---------------- Limites (mesmos do programa em Python) ----------------
// FC em repouso de um adulto costuma ficar entre 60 e 100 BPM.
const int FC_ATENCAO = 110;
const int FC_CRITICO = 130;
const int FC_BAIXA   = 50;
// SpO2 de uma pessoa saudavel costuma ficar entre 95% e 100%.
const int SPO2_ATENCAO = 95;
const int SPO2_CRITICO = 90;
// Temperatura lida pelo sensor (nao e temperatura corporal clinica).
const float TEMP_ATENCAO = 37.8;
const float TEMP_CRITICO = 39.0;
// Movimento: quanto a aceleracao se afasta da gravidade (9,8 m/s2).
// Acima disso o paciente esta se mexendo e a leitura pode nao ser confiavel.
const float LIMITE_MOVIMENTO = 3.0;

// Intervalo entre leituras: 2 segundos (justificativa no README/documento).
const unsigned long INTERVALO_MS = 2000;

OneWire oneWire(PINO_TEMP);
DallasTemperature sensorTemp(&oneWire);
Adafruit_MPU6050 mpu;

unsigned long ultimaLeitura = 0;
bool mpuOk = false;

// ---------------- Funcoes ----------------

// Le o potenciometro e converte para a faixa da FC (40 a 180 BPM)
int lerFC() {
  return map(analogRead(PINO_POT_FC), 0, 4095, 40, 180);
}

// Le o potenciometro e converte para a faixa da SpO2 (80 a 100%)
int lerSpO2() {
  return map(analogRead(PINO_POT_SPO2), 0, 4095, 80, 100);
}

float lerTemperatura() {
  sensorTemp.requestTemperatures();
  return sensorTemp.getTempCByIndex(0);
}

// Retorna o quanto a aceleracao total se afasta da gravidade (m/s2)
float lerMovimento() {
  if (!mpuOk) return 0;
  sensors_event_t a, g, t;
  mpu.getEvent(&a, &g, &t);
  float total = sqrt(a.acceleration.x * a.acceleration.x +
                     a.acceleration.y * a.acceleration.y +
                     a.acceleration.z * a.acceleration.z);
  return fabs(total - 9.8);
}

// Regras de classificacao: o caso mais grave e testado primeiro
String classificar(int fc, int spo2, float temp, String &motivo) {
  motivo = "";
  if (fc >= FC_CRITICO)     motivo += "FC muito alta; ";
  if (spo2 < SPO2_CRITICO)  motivo += "SpO2 muito baixa; ";
  if (temp >= TEMP_CRITICO) motivo += "temperatura muito alta; ";
  if (motivo != "") return "CRITICO";

  if (fc >= FC_ATENCAO)     motivo += "FC alta; ";
  if (fc < FC_BAIXA)        motivo += "FC baixa; ";
  if (spo2 < SPO2_ATENCAO)  motivo += "SpO2 baixa; ";
  if (temp >= TEMP_ATENCAO) motivo += "temperatura alta; ";
  if (motivo != "") return "ATENCAO";

  motivo = "sinais dentro do esperado";
  return "NORMAL";
}

// Acende o LED do estado e toca o buzzer
void alertar(String estado) {
  digitalWrite(LED_VERDE,    estado == "NORMAL");
  digitalWrite(LED_AMARELO,  estado == "ATENCAO");
  digitalWrite(LED_VERMELHO, estado == "CRITICO");

  if (estado == "CRITICO") {
    tone(PINO_BUZZER, 1000, 800);   // bipe longo a cada leitura
  } else if (estado == "ATENCAO") {
    tone(PINO_BUZZER, 600, 150);    // bipe curto a cada leitura
  } else {
    noTone(PINO_BUZZER);
  }
}

String orientacao(String estado) {
  if (estado == "CRITICO") return "Chame a enfermagem imediatamente";
  if (estado == "ATENCAO") return "Avise a enfermagem para reavaliacao";
  return "Continue aguardando";
}

// ---------------- Setup e loop ----------------
void setup() {
  Serial.begin(115200);

  pinMode(LED_VERDE, OUTPUT);
  pinMode(LED_AMARELO, OUTPUT);
  pinMode(LED_VERMELHO, OUTPUT);
  pinMode(PINO_BUZZER, OUTPUT);

  sensorTemp.begin();
  Wire.begin(21, 22);
  mpuOk = mpu.begin();

  Serial.println("=== ZELA - pulseira de monitoramento ===");
  Serial.println("Prototipo academico: nao faz diagnostico.");
  if (!mpuOk) Serial.println("Aviso: MPU6050 nao encontrado, movimento = 0.");
  Serial.println("Formato: t | FC SpO2 TEMP MOV QUAL | ESTADO | motivo | orientacao");
}

void loop() {
  // Leitura periodica sem travar o programa (millis em vez de delay)
  if (millis() - ultimaLeitura >= INTERVALO_MS) {
    ultimaLeitura = millis();

    int fc = lerFC();
    int spo2 = lerSpO2();
    float temp = lerTemperatura();
    float mov = lerMovimento();
    String qualidade = (mov > LIMITE_MOVIMENTO) ? "INSTAVEL" : "OK";

    String motivo;
    String estado = classificar(fc, spo2, temp, motivo);
    alertar(estado);

    // Uma linha por leitura, sempre na mesma ordem
    Serial.print("t="); Serial.print(millis() / 1000); Serial.print("s | ");
    Serial.print("FC="); Serial.print(fc);
    Serial.print(" SpO2="); Serial.print(spo2);
    Serial.print(" TEMP="); Serial.print(temp, 1);
    Serial.print(" MOV="); Serial.print(mov, 1);
    Serial.print(" QUAL="); Serial.print(qualidade);
    Serial.print(" | ESTADO="); Serial.print(estado);
    Serial.print(" | motivo: "); Serial.print(motivo);
    Serial.print(" | "); Serial.println(orientacao(estado));

    if (qualidade == "INSTAVEL") {
      Serial.println("   -> Movimento detectado: fique parado para uma leitura confiavel.");
    }
  }
}

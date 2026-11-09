
#include <Arduino.h>
#include <Wire.h>

#define LED_VERDE 25
#define LED_AMARELO 26
#define LED_VERMELHO 27
#define BUZZER 14

#define SENSOR_TEMP 4
#define SDA_MPU 21
#define SCL_MPU 22


/*
ESP32 -> Controla os sensores, processa as leituras e aciona os alertas
DS18B20 -> Sensor de temperatura que podemos simular no Wokwi.
MPU6050 —> Detecta movimentação e ajuda a identificar possíveis interferências nas leituras.
LEDs / buzzer —> Verde para normal, amarelo para atenção e vermelho com buzzer para crítico.
FC e SpO₂ -> vamos simular essas leituras no código, porque o MAX30102 não está disponível como sensor nativo padrão no Wokwi.
*/
void setup() {
    // Executado somente uma vez
    Serial.begin(115200);

    // Configuração dos LEDs e buzzer
    pinMode(LED_VERDE, OUTPUT);
    pinMode(LED_AMARELO, OUTPUT);
    pinMode(LED_VERMELHO, OUTPUT);
    pinMode(BUZZER, OUTPUT);

    // Configuração do sensor de temperatura
    pinMode(SENSOR_TEMP, INPUT);

    // Inicializa comunicação com MPU6050
    Wire.begin(SDA_MPU, SCL_MPU);

    Serial.println("Sistema de monitoramento iniciado");
}

void loop() {
    // Valores simulados
    int frequenciaCardiaca = random(65, 121);
    int spo2 = random(90, 100);

    Serial.println("-----------------------");
    Serial.print("Frequencia cardiaca: ");
    Serial.println(frequenciaCardiaca);

    Serial.print("SpO2: ");
    Serial.println(spo2);

    // Teste do LED verde
    Serial.println("LED VERDE");
    digitalWrite(LED_VERDE, HIGH);
    delay(1000);
    digitalWrite(LED_VERDE, LOW);

    // Teste do LED amarelo
    Serial.println("LED AMARELO");
    digitalWrite(LED_AMARELO, HIGH);
    delay(1000);
    digitalWrite(LED_AMARELO, LOW);

    // Teste do LED vermelho e buzzer
    Serial.println("LED VERMELHO + BUZZER");
    digitalWrite(LED_VERMELHO, HIGH);
    digitalWrite(BUZZER, HIGH);
    delay(1000);

    digitalWrite(LED_VERMELHO, LOW);
    digitalWrite(BUZZER, LOW);

    delay(2000);
}

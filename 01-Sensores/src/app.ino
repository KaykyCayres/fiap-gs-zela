/*
  Zela - Pulseira de monitoramento na espera do pronto-socorro
  Global Solution 2026 - AI Computer Systems & Sensors (AICSS)
  Kayky Cayres Vicente da Silva (RM 575091)
  Naiara Sousa Soares (RM 574792)
  Rafael Medici (RM 576249)

  O que e REAL no Wokwi (sensor simulado pelo Wokwi):
    - Temperatura: DHT22 (GPIO 4)
  O que e SIMULADO por nos:
    - FC e SpO2: potenciometros (GPIO 34 e 35), no lugar do MAX30102,
      que nao existe no Wokwi e que nao temos no prototipo fisico.
  Saida para o paciente:
    - LEDs, buzzer e tela LCD 16x2 I2C (SDA 21 / SCL 22) com a orientacao.

  MODO DE TESTE: no Monitor Serial, comandos como "fc 125", "temp 39.1" ou "teste3"
  forcam valores para os testes. Sem comando, tudo vem dos sensores. Digite "ajuda".

  ATENCAO: regras experimentais, so para fins academicos.
  O dispositivo NAO faz diagnostico e NAO substitui a equipe de saude.
*/

#include <DHT.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

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

// Intervalo entre leituras: 2 segundos (justificativa no README/documento).
// O DHT22 tambem so entrega uma leitura nova a cada 2 segundos.
const unsigned long INTERVALO_MS = 2000;

DHT dht(PINO_TEMP, DHT22);
LiquidCrystal_I2C lcd(0x27, 16, 2);   // tela 16x2 no endereco I2C 0x27

unsigned long ultimaLeitura = 0;
float ultimaTemp = 36.5;          // ultima temperatura valida do DHT22
String estadoNaTela = "";         // so reescreve a tela quando o estado muda

// ---------------- Modo de teste (comandos pelo Monitor Serial) ----------------
// Para os testes, da para forcar um valor digitando um comando no Monitor Serial.
// Sem comando, a leitura vem dos sensores. A linha do Serial mostra a origem (FONTE).
bool forcaFC = false, forcaSpO2 = false, forcaTemp = false;
int valorFC = 0;
int valorSpO2 = 0;
float valorTemp = 0;
String comando = "";

// ---------------- Funcoes ----------------

// Le o potenciometro e converte para a faixa da FC (40 a 180 BPM)
int lerFC() {
  if (forcaFC) return valorFC;
  return map(analogRead(PINO_POT_FC), 0, 4095, 40, 180);
}

// Le o potenciometro e converte para a faixa da SpO2 (80 a 100%)
int lerSpO2() {
  if (forcaSpO2) return valorSpO2;
  return map(analogRead(PINO_POT_SPO2), 0, 4095, 80, 100);
}

float lerTemperatura() {
  if (forcaTemp) return valorTemp;
  float t = dht.readTemperature();
  if (!isnan(t)) ultimaTemp = t;   // se a leitura falhar, usa a ultima valida
  return ultimaTemp;
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

  // O tone() para sozinho depois do tempo informado, entao no NORMAL
  // nao precisamos chamar noTone() (chamar antes do primeiro tone gera
  // o aviso "LEDC is not initialized" no ESP32).
  if (estado == "CRITICO") {
    tone(PINO_BUZZER, 1000, 800);   // bipe longo a cada leitura
  } else if (estado == "ATENCAO") {
    tone(PINO_BUZZER, 600, 150);    // bipe curto a cada leitura
  }
}

String orientacao(String estado) {
  if (estado == "CRITICO") return "Chame a enfermagem imediatamente";
  if (estado == "ATENCAO") return "Avise a enfermagem para reavaliacao";
  return "Continue aguardando";
}

// Orientacao da tela LCD: versao curta (16 caracteres por linha) da mesma
// orientacao mostrada no programa em Python. A tela nao tem acentos.
void mostrarNaTela(String estado) {
  if (estado == estadoNaTela) return;   // evita a tela piscar a cada leitura
  estadoNaTela = estado;
  lcd.clear();
  lcd.setCursor(0, 0);
  if (estado == "CRITICO") {
    lcd.print("Chame enfermagem");
    lcd.setCursor(0, 1);
    lcd.print("JA ou peca ajuda");
  } else if (estado == "ATENCAO") {
    lcd.print("Sinais alterados");
    lcd.setCursor(0, 1);
    lcd.print("Avise enfermagem");
  } else {
    lcd.print("Aguarde e avise");
    lcd.setCursor(0, 1);
    lcd.print("se sentir algo");
  }
}

// Diz de onde vieram os valores: dos sensores ou de um comando de teste
String fonteDosValores() {
  if (!forcaFC && !forcaSpO2 && !forcaTemp) return "SENSOR";
  String lista = "";
  if (forcaFC)   lista += "FC,";
  if (forcaSpO2) lista += "SpO2,";
  if (forcaTemp) lista += "TEMP,";
  lista.remove(lista.length() - 1);   // tira a ultima virgula
  return "TESTE(" + lista + ")";
}

// ---------------- Cenarios de teste: "teste1" a "teste6" ----------------
// Cada teste tem etapas. "teste3" roda o teste inteiro, passando sozinho pelas etapas;
// "teste3b" aplica so a etapa b; "proximo" passa para a etapa seguinte do teste em andamento.
struct Etapa {
  int fc;
  int spo2;
  float temp;
  const char* nome;
};

const Etapa TESTE_1[] = {{78, 98, 36.5, "paciente estavel"}};
const Etapa TESTE_2[] = {{104, 98, 36.5, "FC 104 (normal)"},
                         {125, 98, 36.5, "FC 125 (alta)"}};
const Etapa TESTE_3[] = {{78, 98, 36.5, "SpO2 98 (normal)"},
                         {78, 93, 36.5, "SpO2 93 (baixa)"},
                         {78, 85, 36.5, "SpO2 85 (muito baixa)"}};
const Etapa TESTE_4[] = {{125, 100, 36.5, "FC 125 e SpO2 100"},
                         {129, 100, 36.5, "FC 129 (abaixo do limite critico)"},
                         {129, 86, 36.5, "FC 129 e SpO2 86"}};
const Etapa TESTE_5[] = {{78, 98, 38.9, "temperatura 38.9"},
                         {78, 98, 38.0, "temperatura 38.0"}};
const Etapa TESTE_6[] = {{78, 98, 36.5, "temperatura 36.5 (normal)"},
                         {78, 98, 38.3, "temperatura 38.3 (alta)"},
                         {78, 98, 39.1, "temperatura 39.1 (muito alta)"}};

const Etapa* const CENARIOS[6] = {TESTE_1, TESTE_2, TESTE_3, TESTE_4, TESTE_5, TESTE_6};
const int TOTAL_ETAPAS[6] = {1, 2, 3, 3, 2, 3};
int cenarioAtual = 0;   // 0 = nenhum teste em andamento
int etapaAtual = 0;
const unsigned long TEMPO_ETAPA_MS = 6000;   // em "testeN", cada etapa dura 6 s (3 leituras)
bool avancoAutomatico = false;
unsigned long proximaEtapaEm = 0;

// Forca todos os valores da etapa atual do teste atual
void aplicarEtapa() {
  const Etapa &e = CENARIOS[cenarioAtual - 1][etapaAtual];
  forcaFC = forcaSpO2 = forcaTemp = true;
  valorFC = e.fc;
  valorSpO2 = e.spo2;
  valorTemp = e.temp;
  int total = TOTAL_ETAPAS[cenarioAtual - 1];
  Serial.print("[teste] Teste "); Serial.print(cenarioAtual);
  Serial.print(" - etapa "); Serial.print(etapaAtual + 1);
  Serial.print(" de "); Serial.print(total);
  Serial.print(": "); Serial.println(e.nome);
  if (etapaAtual + 1 < total) {
    if (avancoAutomatico) {
      Serial.println("[teste] Proxima etapa em 6 segundos.");
      proximaEtapaEm = millis() + TEMPO_ETAPA_MS;
    } else {
      Serial.println("[teste] Digite 'proximo' para a proxima etapa.");
    }
  } else {
    avancoAutomatico = false;
    Serial.println("[teste] Ultima etapa. Digite 'auto' para voltar aos sensores.");
  }
  ultimaLeitura = millis() - INTERVALO_MS;   // faz uma leitura na hora, para o LED mudar logo
}

void mostrarAjuda() {
  Serial.println("[teste] Testes prontos: teste1 a teste6 (passam sozinhos pelas etapas) | teste3b (so uma etapa) | auto");
  Serial.println("[teste] Valores soltos: fc 125 | spo2 85 | temp 39.1 | auto fc | ajuda");
  Serial.println("[teste] 'auto' volta a ler os sensores. Faixas: FC 20-250, SpO2 50-100, TEMP 30-45");
}

// Trata um comando digitado no Monitor Serial
void processarComando(String c) {
  c.trim();
  c.toLowerCase();
  c.replace("=", " ");
  if (c.length() == 0) return;

  int espaco = c.indexOf(' ');
  String nome = (espaco < 0) ? c : c.substring(0, espaco);
  String resto = (espaco < 0) ? "" : c.substring(espaco + 1);
  resto.trim();

  if (nome == "ajuda") {
    mostrarAjuda();
    return;
  }

  // "teste3": roda o teste 3 inteiro, passando sozinho pelas etapas (uma a cada 6 s).
  // "teste3b": aplica so a etapa b do teste 3 e fica nela.
  if (nome.startsWith("teste")) {
    String numero = nome.substring(5);
    if (numero == "") numero = resto;
    int n = numero.toInt();
    int etapa = 0;
    bool temLetra = false;
    if (numero.length() > 0) {
      char letra = numero.charAt(numero.length() - 1);   // "3b" -> 'b'
      if (letra >= 'a' && letra <= 'c') { etapa = letra - 'a'; temLetra = true; }
    }
    if (n >= 1 && n <= 6 && etapa < TOTAL_ETAPAS[n - 1]) {
      cenarioAtual = n;
      etapaAtual = etapa;
      avancoAutomatico = !temLetra;   // sem letra: passa sozinho pelas etapas
      aplicarEtapa();
    } else {
      Serial.print("[teste] Teste invalido: '"); Serial.print(c); Serial.println("'. Digite 'ajuda' para ver a lista.");
    }
    return;
  }

  // "proximo" (ou "p"): passa para a etapa seguinte do teste em andamento
  if (nome == "proximo" || nome == "p") {
    if (cenarioAtual == 0) {
      Serial.println("[teste] Nenhum teste em andamento. Digite teste1 a teste6.");
    } else if (etapaAtual + 1 >= TOTAL_ETAPAS[cenarioAtual - 1]) {
      Serial.print("[teste] O teste "); Serial.print(cenarioAtual);
      Serial.print(" so tem "); Serial.print(TOTAL_ETAPAS[cenarioAtual - 1]);
      Serial.print(" etapa(s) e ja esta na ultima. Digite 'auto' para voltar aos sensores ou outro teste (teste1 a teste6).");
      Serial.println();
    } else {
      avancoAutomatico = false;
      etapaAtual++;
      aplicarEtapa();
    }
    return;
  }

  if (nome == "auto") {
    if (resto == "" || resto == "tudo") {
      forcaFC = forcaSpO2 = forcaTemp = false;
      cenarioAtual = 0;
      avancoAutomatico = false;
      Serial.println("[teste] Todos os valores voltaram a vir dos sensores.");
    } else if (resto == "fc")   { forcaFC = false;   Serial.println("[teste] FC volta a vir do sensor."); }
    else if (resto == "spo2")   { forcaSpO2 = false; Serial.println("[teste] SpO2 volta a vir do sensor."); }
    else if (resto == "temp")   { forcaTemp = false; Serial.println("[teste] TEMP volta a vir do sensor."); }
    else { Serial.print("[teste] Comando invalido: '"); Serial.print(c); Serial.println("'. Digite 'ajuda'."); return; }
    ultimaLeitura = millis() - INTERVALO_MS;   // faz uma leitura na hora
    return;
  }

  if (resto == "") {
    Serial.print("[teste] Comando invalido: '"); Serial.print(c); Serial.println("'. Digite 'ajuda'.");
    return;
  }
  float valor = resto.toFloat();

  if (nome == "fc" && valor >= 20 && valor <= 250) {
    forcaFC = true; valorFC = (int)(valor + 0.5);
    Serial.print("[teste] FC forcada em "); Serial.println(valorFC);
  } else if (nome == "spo2" && valor >= 50 && valor <= 100) {
    forcaSpO2 = true; valorSpO2 = (int)(valor + 0.5);
    Serial.print("[teste] SpO2 forcada em "); Serial.println(valorSpO2);
  } else if (nome == "temp" && valor >= 30 && valor <= 45) {
    forcaTemp = true; valorTemp = valor;
    Serial.print("[teste] TEMP forcada em "); Serial.println(valorTemp, 1);
  } else {
    Serial.print("[teste] Comando ou valor invalido: '"); Serial.print(c); Serial.println("'. Digite 'ajuda'.");
    return;
  }
  ultimaLeitura = millis() - INTERVALO_MS;   // faz uma leitura na hora, para o LED mudar logo
}

// Junta os caracteres digitados e trata o comando so quando chega o Enter
// (o terminal envia uma tecla de cada vez, entao nao da para adivinhar o fim do comando)
void lerComandosSerial() {
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n' || c == '\r') {
      if (comando.length() > 0) {
        processarComando(comando);
        comando = "";
      }
    } else if (comando.length() < 40) {   // limite para nao encher a memoria
      comando += c;
    }
  }
}

// ---------------- Setup e loop ----------------
void setup() {
  Serial.begin(115200);

  pinMode(LED_VERDE, OUTPUT);
  pinMode(LED_AMARELO, OUTPUT);
  pinMode(LED_VERMELHO, OUTPUT);
  pinMode(PINO_BUZZER, OUTPUT);

  dht.begin();
  Wire.begin(21, 22);
  lcd.init();
  lcd.backlight();

  Serial.println("=== ZELA - pulseira de monitoramento ===");
  Serial.println("Prototipo academico: nao faz diagnostico.");
  Serial.println("Formato: t | FC SpO2 TEMP FONTE | ESTADO | motivo | orientacao");
  Serial.println("Modo de teste: digite 'ajuda' no Monitor Serial para ver os comandos.");
}

void loop() {
  lerComandosSerial();

  // Teste em andamento: passa sozinho para a proxima etapa quando o tempo acaba
  if (avancoAutomatico && cenarioAtual != 0 && millis() >= proximaEtapaEm) {
    etapaAtual++;
    aplicarEtapa();
  }

  // Leitura periodica sem travar o programa (millis em vez de delay)
  if (millis() - ultimaLeitura >= INTERVALO_MS) {
    ultimaLeitura = millis();

    int fc = lerFC();
    int spo2 = lerSpO2();
    float temp = lerTemperatura();

    String motivo;
    String estado = classificar(fc, spo2, temp, motivo);
    if (motivo.endsWith("; ")) motivo.remove(motivo.length() - 2);   // tira o ultimo "; "
    
    // Uma linha por leitura, sempre na mesma ordem
    Serial.print("t="); Serial.print(millis() / 1000); Serial.print("s | ");
    Serial.print("FC="); Serial.print(fc);
    Serial.print(" SpO2="); Serial.print(spo2);
    Serial.print(" TEMP="); Serial.print(temp, 1);
    Serial.print(" FONTE="); Serial.print(fonteDosValores());
    Serial.print(" | ESTADO="); Serial.print(estado);
    Serial.print(" | motivo: "); Serial.print(motivo);
    Serial.print(" | "); Serial.println(orientacao(estado));

     // LEDs, buzzer e tela depois de imprimir, para nenhum aviso interno do ESP32
    // aparecer no meio da linha do Serial
    alertar(estado);
    mostrarNaTela(estado);
  }
}

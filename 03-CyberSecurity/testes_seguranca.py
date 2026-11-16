"""Tres testes de seguranca da Zela (entradas, esperado, protecao, resultado)."""
import csv
import shutil
from seguranca import (validar_medicao, classificar, registrar_hash,
                       processar_csv, linha_segura, CAMPOS_PESSOAIS)

ORIGINAL = "medicoes_pulseira_simuladas.csv"

print("=" * 66)
print("TESTE 1 - Entrada invalida (protecao: validacao de entrada)")
print("=" * 66)
casos = [("75", "98", "36.5"), ("abc", "97", "36.6"), ("900", "96", "36.6"),
         ("80", "150", "36.6"), ("-5", "95", "36.6"), ("80", "97", "55"),
         ("80", "98", "38.0"), ("135", "88", "39.2")]
for fc, spo2, temp in casos:
    ok, f, s, t, motivo = validar_medicao(fc, spo2, temp)
    resultado = classificar(f, s, t) if ok else "RECUSADA - " + motivo
    print(f"Entrada FC={fc:>4} SpO2={spo2:>4} Temp={temp:>4} -> {resultado}")

print()
print("=" * 66)
print("TESTE 2 - Arquivo alterado (protecao: hash SHA-256)")
print("=" * 66)
registrar_hash(ORIGINAL)
print("a) Arquivo original:")
processar_csv(ORIGINAL, 4, limite=4)
copia = "medicoes_alterado.csv"
shutil.copy(ORIGINAL + ".sha256", copia + ".sha256")
with open(ORIGINAL, encoding="utf-8-sig", newline="") as f:
    leitor = csv.DictReader(f)
    colunas = leitor.fieldnames
    linhas = list(leitor)
ultima = [l for l in linhas if l["paciente_id"] == "4"][-1]
print(f"\nb) Alguem troca a SpO2 da ultima leitura do paciente 4: {ultima['spo2']} -> 99.0")
ultima["spo2"] = "99.0"
with open(copia, "w", newline="", encoding="utf-8-sig") as f:
    escritor = csv.DictWriter(f, fieldnames=colunas)
    escritor.writeheader()
    escritor.writerows(linhas)
processar_csv(copia, 4)

print()
print("=" * 66)
print("TESTE 3 - Dados pessoais (protecao: pseudonimo / LGPD)")
print("=" * 66)
registro = {"paciente_id": "7", "nome": "Maria da Silva", "cpf": "123.456.789-00",
            "frequencia_cardiaca": "118", "spo2": "93.5", "temperatura": "37.9"}
print("Entrada recebida (dados ficticios):")
for campo, valor in registro.items():
    print(f"   {campo}: {valor}")
ok, fc, spo2, temp, _ = validar_medicao(registro["frequencia_cardiaca"], registro["spo2"],
                                        registro["temperatura"])
saida = linha_segura(registro, classificar(fc, spo2, temp))
print("Saida exibida   :", saida)
vazou = [c for c in CAMPOS_PESSOAIS if c in registro and registro[c] in saida]
print("Dados pessoais na saida:", vazou if vazou else "nenhum")

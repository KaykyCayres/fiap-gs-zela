"""Tres testes de seguranca da Zela (entradas, esperado, protecao, resultado)."""
import csv
import shutil
from seguranca import (validar_medicao, classificar, registrar_hash,
                       processar_csv, linha_segura, CAMPOS_PESSOAIS)

ORIGINAL = "medicoes_pulseira_simuladas.csv"

print("=" * 62)
print("TESTE 1 - Entrada invalida (protecao: validacao de entrada)")
print("=" * 62)
casos = [("75", "98"), ("abc", "97"), ("900", "96"), ("80", "150"), ("-5", "95"), ("135", "88")]
for fc, spo2 in casos:
    ok, f, s, motivo = validar_medicao(fc, spo2)
    resultado = classificar(f, s) if ok else "RECUSADA - " + motivo
    print(f"Entrada FC={fc:>4} SpO2={spo2:>4} -> {resultado}")

print()
print("=" * 62)
print("TESTE 2 - Arquivo alterado (protecao: hash SHA-256)")
print("=" * 62)
registrar_hash(ORIGINAL)
print("a) Arquivo original:")
processar_csv(ORIGINAL, 4, limite=4)
copia = "medicoes_alterado.csv"
shutil.copy(ORIGINAL, copia)
shutil.copy(ORIGINAL + ".sha256", copia + ".sha256")
with open(copia, encoding="utf-8-sig") as f:
    linhas = list(csv.reader(f))
for linha in linhas:
    if linha[0] == "4" and linha[2] == "36":
        print(f"\nb) Alguem troca a SpO2 critica do paciente 4: {linha[5]} -> 99.0")
        linha[5] = "99.0"
with open(copia, "w", newline="", encoding="utf-8-sig") as f:
    csv.writer(f).writerows(linhas)
processar_csv(copia, 4)

print()
print("=" * 62)
print("TESTE 3 - Dados pessoais (protecao: pseudonimo / LGPD)")
print("=" * 62)
registro = {"paciente_id": "7", "nome": "Maria da Silva", "cpf": "123.456.789-00",
            "frequencia_cardiaca": "118", "spo2": "93.5"}
print("Entrada recebida (dados ficticios):")
for campo, valor in registro.items():
    print(f"   {campo}: {valor}")
ok, fc, spo2, _ = validar_medicao(registro["frequencia_cardiaca"], registro["spo2"])
saida = linha_segura(registro, classificar(fc, spo2))
print("Saida exibida   :", saida)
vazou = [c for c in CAMPOS_PESSOAIS if c in registro and registro[c] in saida]
print("Dados pessoais na saida:", vazou if vazou else "nenhum")

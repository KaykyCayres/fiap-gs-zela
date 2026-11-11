"""
ZELA - Pulseira de monitoramento na espera do pronto-socorro
Global Solution 2026.2 - Cognitive Cyber Security
Integrantes: Naiara Sousa Soares (RM 574792), Rafael Medici (RM 576249), Kayky Cayres Vicente da Silva (RM 575091)

Protecoes basicas aplicadas ao fluxo da pulseira:
  1. Validacao de entrada  -> recusa valores que nao sao numeros ou impossiveis
  2. Integridade do arquivo -> detecta se o CSV foi alterado depois de gerado
  3. Privacidade (LGPD)     -> mostra so um codigo do paciente, nunca nome ou CPF

Limites de classificacao: DEMONSTRACAO academica, sem valor clinico.
"""
import csv
import hashlib
import os

# Faixas possiveis para o sensor (fora disso a leitura e considerada erro)
FAIXA_FC = (20, 250)      # batimentos por minuto (mesma faixa do monitor_pulseira.py)
FAIXA_SPO2 = (50, 100)    # saturacao de oxigenio em %

# Campos que nunca podem aparecer na saida
CAMPOS_PESSOAIS = ["nome", "cpf", "telefone", "endereco", "email"]


def validar_medicao(fc_texto, spo2_texto):
    """Protecao 1: confere se as duas medicoes sao numeros dentro da faixa."""
    try:
        fc = float(fc_texto)
        spo2 = float(spo2_texto)
    except ValueError:
        return False, None, None, "valor nao numerico"
    if not (FAIXA_FC[0] <= fc <= FAIXA_FC[1]):
        return False, None, None, f"FC {fc:g} fora da faixa {FAIXA_FC}"
    if not (FAIXA_SPO2[0] <= spo2 <= FAIXA_SPO2[1]):
        return False, None, None, f"SpO2 {spo2:g} fora da faixa {FAIXA_SPO2}"
    return True, fc, spo2, "ok"


def classificar(fc, spo2):
    """Mesmas regras do monitor_pulseira.py (Python) e do ESP32 (AICSS)."""
    if fc >= 130 or spo2 < 90:
        return "CRITICO"
    if fc >= 110 or fc < 50 or spo2 < 95:
        return "ATENCAO"
    return "NORMAL"


def calcular_hash(caminho):
    """Gera a 'impressao digital' (SHA-256) do arquivo."""
    with open(caminho, "rb") as arquivo:
        return hashlib.sha256(arquivo.read()).hexdigest()


def registrar_hash(caminho):
    """Guarda o hash original logo depois que o CSV e gerado."""
    with open(caminho + ".sha256", "w") as f:
        f.write(calcular_hash(caminho))


def arquivo_integro(caminho):
    """Protecao 2: compara o hash atual com o hash guardado."""
    if not os.path.exists(caminho + ".sha256"):
        return False
    with open(caminho + ".sha256") as f:
        original = f.read().strip()
    return calcular_hash(caminho) == original


def codigo_paciente(paciente_id):
    """Protecao 3: troca a identificacao por um codigo (pseudonimo)."""
    return f"PAC-{int(paciente_id):04d}"


def linha_segura(registro, nivel):
    """Monta a saida so com o codigo do paciente e as medicoes."""
    return (f"{codigo_paciente(registro['paciente_id'])} | "
            f"FC: {registro['frequencia_cardiaca']} bpm | "
            f"SpO2: {registro['spo2']} % | {nivel}")


def processar_csv(caminho, paciente_id=None, limite=None):
    """Fluxo completo: integridade -> validacao -> classificacao -> saida segura."""
    print(f"\nArquivo: {os.path.basename(caminho)}")
    if not arquivo_integro(caminho):
        print("BLOQUEADO: o arquivo foi alterado ou nao tem registro de origem.")
        print("Nenhuma orientacao foi gerada.")
        return None
    print("Integridade conferida: arquivo igual ao original.")
    resumo = {"NORMAL": 0, "ATENCAO": 0, "CRITICO": 0, "RECUSADA": 0}
    with open(caminho, encoding="utf-8-sig") as f:
        for registro in csv.DictReader(f):
            if paciente_id and registro["paciente_id"] != str(paciente_id):
                continue
            ok, fc, spo2, motivo = validar_medicao(registro["frequencia_cardiaca"],
                                                   registro["spo2"])
            if not ok:
                resumo["RECUSADA"] += 1
                print(f"{codigo_paciente(registro['paciente_id'])} | RECUSADA: {motivo}")
                continue
            nivel = classificar(fc, spo2)
            resumo[nivel] += 1
            exibidas = sum(resumo.values())
            if limite is None or exibidas <= limite:
                print(linha_segura(registro, nivel))
            elif exibidas == limite + 1:
                print("...")
    print("Resumo:", resumo)
    return resumo


def menu():
    caminho = "medicoes_pulseira_simuladas.csv"
    print("=== ZELA - VERIFICACAO DE SEGURANCA ===")
    print("1 - Registrar hash do CSV (logo apos gerar os dados)")
    print("2 - Processar medicoes de um paciente")
    print("3 - Digitar uma medicao")
    opcao = input("Escolha: ").strip()
    if opcao == "1":
        registrar_hash(caminho)
        print("Hash registrado:", calcular_hash(caminho)[:16], "...")
    elif opcao == "2":
        processar_csv(caminho, input("ID do paciente: ").strip())
    elif opcao == "3":
        ok, fc, spo2, motivo = validar_medicao(input("FC (bpm): "), input("SpO2 (%): "))
        print(classificar(fc, spo2) if ok else f"RECUSADA: {motivo}")
    else:
        print("Opcao invalida.")


if __name__ == "__main__":
    menu()

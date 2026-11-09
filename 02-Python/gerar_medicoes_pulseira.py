"""Gera séries TEMPORAIS SINTÉTICAS a partir de registros do Zenodo.
Uso exclusivamente acadêmico; não define triagem ou limiares clínicos.
python gerar_medicoes_pulseira.py --entrada "five vital signs of normal people.csv" --saida medicoes_pulseira_simuladas.csv
"""
import argparse
import numpy as np
import pandas as pd

CAMPOS = {
    'pressao_diastolica': 'Diastolic blood pressure reading',
    'pressao_sistolica': 'Systolic blood pressure reading',
    'frequencia_cardiaca': 'Heart rate reading',
    'spo2': 'Oxygen saturation reading',
    'temperatura': 'Temperature reading',
}
# Perfis de DEMONSTRAÇÃO, não classificação médica.
PERFIS = {
    'ESTAVEL': {'fc': 0, 'spo2': 0, 'temp': 0, 'pas': 0, 'pad': 0},
    'FC_ELEVANDO': {'fc': 38, 'spo2': -1, 'temp': 0.2, 'pas': 12, 'pad': 5},
    'SPO2_CAINDO': {'fc': 16, 'spo2': -9, 'temp': 0.1, 'pas': -5, 'pad': -2},
    'COMBINADO': {'fc': 48, 'spo2': -12, 'temp': 1.2, 'pas': -15, 'pad': -8},
    'RECUPERACAO': {'fc': 34, 'spo2': -7, 'temp': 0.5, 'pas': -8, 'pad': -4},
}

def curva(perfil, t, total):
    x = t / max(total - 1, 1)
    if perfil == 'RECUPERACAO':
        return np.sin(np.pi * x) ** 2
    return 3*x*x - 2*x*x*x  # transição suave

def gerar(entrada, saida, por_paciente=36, seed=2026):
    rng = np.random.default_rng(seed)
    original = pd.read_csv(entrada)
    colunas_necessarias = ['Subject ID'] + [f'{prefix} {i}' for prefix in CAMPOS.values() for i in range(1,10)]
    faltando = [c for c in colunas_necessarias if c not in original.columns]
    if faltando:
        raise ValueError(f'Colunas ausentes: {faltando}')
    registros = []
    perfis = list(PERFIS)
    for pos, (_, pessoa) in enumerate(original.iterrows()):
        perfil = perfis[pos % len(perfis)]
        # Mediana das 9 leituras reais: referência individual, sem modificar a fonte.
        base = {nome: float(np.median([pessoa[f'{prefix} {i}'] for i in range(1, 10)]))
                for nome, prefix in CAMPOS.items()}
        ruido = {nome: 0.0 for nome in CAMPOS}
        for t in range(por_paciente):
            fator = curva(perfil, t, por_paciente)
            d = PERFIS[perfil]
            # Ruído autocorrelacionado: oscilações pequenas e graduais, não saltos independentes.
            for nome, desvio in [('frequencia_cardiaca', 1.8), ('spo2', 0.45), ('temperatura', 0.07),
                                 ('pressao_sistolica', 2.2), ('pressao_diastolica', 1.5)]:
                ruido[nome] = 0.75 * ruido[nome] + rng.normal(0, desvio)
            fc = np.clip(base['frequencia_cardiaca'] + d['fc'] * fator + ruido['frequencia_cardiaca'], 40, 185)
            spo2 = np.clip(base['spo2'] + d['spo2'] * fator + ruido['spo2'], 75, 100)
            temp = np.clip(base['temperatura'] + d['temp'] * fator + ruido['temperatura'], 32, 41)
            pas = np.clip(base['pressao_sistolica'] + d['pas'] * fator + ruido['pressao_sistolica'], 70, 210)
            pad = np.clip(base['pressao_diastolica'] + d['pad'] * fator + ruido['pressao_diastolica'], 40, min(130, pas-10))
            registros.append({
                'paciente_id': int(pessoa['Subject ID']), 'dispositivo_id': f'ESP32-{pos+1:04d}',
                'leitura_numero': t+1, 'tempo_espera_min': t*2,
                'frequencia_cardiaca': int(round(fc)), 'spo2': round(float(spo2),1),
                'temperatura': round(float(temp),2), 'pressao_sistolica': int(round(pas)),
                'pressao_diastolica': int(round(pad)),
                'cenario_simulado': perfil, 'origem_dado': 'SIMULADO',
                # Os valores são SIMULADOS; o Zenodo serve só como referência de faixa por paciente.
                'fonte_referencia': 'Simulado - faixas inspiradas no dataset Zenodo (Nine readings per subject)',
            })
    df = pd.DataFrame(registros)
    df.to_csv(saida, index=False, encoding='utf-8-sig')
    return df

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--entrada', default='Texto colado(4).txt')
    ap.add_argument('--saida', default='medicoes_pulseira_simuladas.csv')
    ap.add_argument('--por-paciente', type=int, default=36)
    ap.add_argument('--seed', type=int, default=2026)
    args = ap.parse_args()
    df = gerar(args.entrada, args.saida, args.por_paciente, args.seed)
    print(f'Geradas {len(df)} medições sintéticas para {df.paciente_id.nunique()} participantes.')
    print(df.groupby('cenario_simulado').size().to_string())
"""
Monitor de Pulseira Inteligente - Global Solution 2026 - Citizen Tech
Computational Thinking with Python

Classifica leituras de frequência cardíaca (FC), oxigenação (SpO2) e
temperatura de pacientes que aguardam atendimento no pronto-socorro e
mostra uma orientação ao paciente.

ATENCAO: regras experimentais, criadas só para fins acadêmicos.
O programa NÃO faz diagnóstico e NÃO substitui a equipe de saude.

| Integrante | RM |
|---|---|
| Kayky Cayres Vicente da Silva | 575091 |
| Naiara Sousa Soares | 574792 |
| Rafael Medici | 576249 |
"""

import csv
import os

# Procura o CSV na mesma pasta deste arquivo .py
PASTA_DO_PROGRAMA = os.path.dirname(os.path.abspath(__file__))
ARQUIVO_CSV = os.path.join(PASTA_DO_PROGRAMA, 'medicoes_pulseira_simuladas.csv')



# ---------------------------------------cls------------------------
# Limites usados nas regras (valores de referência simplificados)
# São os mesmos da pulseira (firmware) e do banco de dados.
# ---------------------------------------------------------------
# FC em repouso de um adulto costuma ficar entre 60 e 100 BPM.
# Acima de 110 consideramos ATENCAO e a partir de 130, CRITICO.
# Abaixo de 50 também pede ATENCAO (batimento lento demais).
FC_ATENCAO = 110
FC_CRITICO = 130
FC_BAIXA = 50

# SpO2 de uma pessoa saudavel costuma ficar entre 95% e 100%.
# Abaixo de 95% consideramos ATENCAO e abaixo de 90%, CRITICO.
SPO2_ATENCAO = 95
SPO2_CRITICO = 90

# Temperatura: a partir de 37,8 °C consideramos ATENCAO e de 39,0 °C, CRITICO.
# É a temperatura lida pela pulseira, não uma medida clínica.
TEMP_ATENCAO = 37.8
TEMP_CRITICO = 39.0

# Faixas aceitas na digitação (evita valores impossíveis)
FC_MIN, FC_MAX = 20, 250
SPO2_MIN, SPO2_MAX = 50, 100
TEMP_MIN, TEMP_MAX = 30, 45

# Orientação ao paciente para cada estado.
# Sempre encaminha para a equipe; nunca indica remedio / conduta.
RECOMENDACOES = {
    'NORMAL': 'Sinais dentro do esperado. Continue aguardando e avise a equipe se sentir algo diferente.',
    'ATENCAO': 'Sinais fora do esperado. Avise a equipe de enfermagem para uma reavaliação.',
    'CRITICO': 'Sinais preocupantes. Chame a enfermagem imediatamente ou peça ajuda a quem estiver perto.',
}


class MonitorPaciente:
    """Representa a pulseira de um paciente e guarda o histórico de leituras."""

    def __init__(self, paciente_id):
        self.paciente_id = paciente_id
        self.historico = []  # lista de dicionarios, uma leitura por item

    def classificar(self, fc, spo2, temp):
        # A regra mais grave é testada primeiro.
        if fc >= FC_CRITICO or spo2 < SPO2_CRITICO or temp >= TEMP_CRITICO:
            return 'CRITICO'
        elif fc >= FC_ATENCAO or fc < FC_BAIXA or spo2 < SPO2_ATENCAO or temp >= TEMP_ATENCAO:
            return 'ATENCAO'
        else:
            return 'NORMAL'

    def recomendar(self, estado):
        return RECOMENDACOES[estado]

    def registrar(self, fc, spo2, temp):
        estado = self.classificar(fc, spo2, temp)
        leitura = {'fc': fc, 'spo2': spo2, 'temp': temp, 'estado': estado}
        self.historico.append(leitura)

        print(f'FC: {fc} BPM | SpO2: {spo2}% | Temperatura: {temp:.1f} °C | Estado: {estado} -> {self.recomendar(estado)}')
        return estado

    def resumo(self):
        estados = [leitura['estado'] for leitura in self.historico]
        print(f'\n--- Resumo do paciente {self.paciente_id} ---')
        print('Total de medições:', len(estados))
        print('Normal:', estados.count('NORMAL'))
        print('Atenção:', estados.count('ATENCAO'))
        print('Crítico:', estados.count('CRITICO'))
        if 'CRITICO' in estados:
            print('Houve leitura CRÍTICA: a equipe deve reavaliar este paciente.')


def ler_numero(mensagem, minimo, maximo):
    """Pede um número ao usuario ate ele digitar um valor válido."""
    while True:
        texto = input(mensagem).replace(',', '.')  # aceita 97,5 ou 97.5
        try:
            valor = float(texto)
        except ValueError:
            print('Digite apenas números.')
            continue

        if valor < minimo or valor > maximo:
            print(f'Valor fora da faixa aceita ({minimo} a {maximo}).')
        else:
            return valor


def ler_csv(nome_arquivo, paciente_id):
    monitor = MonitorPaciente(paciente_id)

    with open(nome_arquivo, 'r', encoding='utf-8-sig', newline='') as arquivo:
        leitor = csv.DictReader(arquivo)
        for linha in leitor:
            if linha['paciente_id'] == paciente_id:
                print(f"Leitura {linha['leitura_numero']} "
                      f"({linha['tempo_espera_min']} min de espera):")
                monitor.registrar(int(linha['frequencia_cardiaca']),
                                  float(linha['spo2']),
                                  float(linha['temperatura']))

    if len(monitor.historico) == 0:
        print('Nenhuma medição encontrada para esse paciente.')
    else:
        monitor.resumo()


def digitar_medicoes():
    monitor = MonitorPaciente('MANUAL')

    while True:
        fc = int(ler_numero('Frequência cardíaca (BPM): ', FC_MIN, FC_MAX))
        spo2 = ler_numero('Oxigenação (SpO2 %): ', SPO2_MIN, SPO2_MAX)
        temp = ler_numero('Temperatura (°C): ', TEMP_MIN, TEMP_MAX)
        monitor.registrar(fc, spo2, temp)

        continuar = input('Deseja fazer outra medição? (s/n): ').lower()
        if continuar != 's':
            break

    monitor.resumo()


def demonstrar_cenarios():
    """3 cenarios de teste pedidos no enunciado."""
    cenarios = [
        ('Cenário 1 - paciente estável', 78, 98, 36.6),
        ('Cenário 2 - FC elevada, SpO2 um pouco baixa e temperatura alta', 115, 93, 37.9),
        ('Cenário 3 - FC muito alta, SpO2 baixa e febre', 138, 88, 39.2),
    ]

    monitor = MonitorPaciente('DEMO')
    for nome, fc, spo2, temp in cenarios:
        print(f'\n{nome}')
        print(f'Entrada: FC = {fc} BPM, SpO2 = {spo2}%, Temperatura = {temp} °C')
        monitor.registrar(fc, spo2, temp)

    monitor.resumo()


def main():
    print('=== MONITOR DE PULSEIRA ===')
    print('Protótipo acadêmico: não faz diagnóstico.\n')
    print('1 - Ler medições do CSV')
    print('2 - Digitar medições')
    print('3 - Demonstrar os 3 cenários de teste')
    opcao = input('Escolha uma opção: ')

    if opcao == '1':
        paciente = input('Informe o ID do paciente (1 a 102): ')
        try:
            ler_csv(ARQUIVO_CSV, paciente)
        except FileNotFoundError:
            print('CSV não encontrado em:', ARQUIVO_CSV)
            print('Confira se o nome do arquivo está exatamente igual.')
    elif opcao == '2':
        digitar_medicoes()
    elif opcao == '3':
        demonstrar_cenarios()
    else:
        print('Opção invalida.')


if __name__ == '__main__':
    main()

import csv


class MonitorPaciente:
    def __init__(self, paciente_id):
        self.paciente_id = paciente_id
        self.historico = []

    def classificar(self, frequencia_cardiaca, spo2):
        # Regras fictícias para demonstrar os 3 estados do projeto.
        # Não devem ser usadas para decisões médicas.
        if frequencia_cardiaca >= 130 or spo2 < 90:
            return 'CRITICO'
        elif frequencia_cardiaca >= 110 or frequencia_cardiaca < 50 or spo2 < 95:
            return 'ATENCAO'
        else:
            return 'NORMAL'

    def registrar(self, frequencia_cardiaca, spo2):
        estado = self.classificar(frequencia_cardiaca, spo2)
        self.historico.append(estado)
        print('FC:', frequencia_cardiaca, 'BPM | SpO2:', spo2, '% | Estado:', estado)


def ler_csv(nome_arquivo, paciente_id):
    monitor = MonitorPaciente(paciente_id)

    with open(nome_arquivo, 'r', encoding='utf-8-sig', newline='') as arquivo:
        leitor = csv.DictReader(arquivo)

        for linha in leitor:
            if linha['paciente_id'] == paciente_id:
                fc = int(linha['frequencia_cardiaca'])
                spo2 = float(linha['spo2'])
                monitor.registrar(fc, spo2)

    if len(monitor.historico) == 0:
        print('Nenhuma medição encontrada para esse paciente.')
    else:
        print('\nTotal de medições:', len(monitor.historico))
        print('Normal:', monitor.historico.count('NORMAL'))
        print('Atenção:', monitor.historico.count('ATENCAO'))
        print('Crítico:', monitor.historico.count('CRITICO'))


def digitar_medicoes():
    monitor = MonitorPaciente('MANUAL')

    while True:
        try:
            fc = int(input('Frequência cardíaca (BPM): '))
            spo2 = float(input('Oxigenação (SpO2 %): '))

            if fc <= 0 or spo2 <= 0 or spo2 > 100:
                print('Digite valores válidos.')
                continue

            monitor.registrar(fc, spo2)
        except ValueError:
            print('Digite apenas números.')
            continue

        continuar = input('Deseja fazer outra medição? (s/n): ').lower()
        if continuar != 's':
            break

    print('Histórico:', monitor.historico)


print('=== MONITOR DE PULSEIRA ===')
print('1 - Ler medições do CSV')
print('2 - Digitar medições')
opcao = input('Escolha uma opção: ')

if opcao == '1':
    paciente = input('Informe o ID do paciente: ')
    try:
        ler_csv('medicoes_pulseira_simuladas.csv', paciente)
    except FileNotFoundError:
        print('CSV não encontrado. Coloque o arquivo na mesma pasta do programa.')
elif opcao == '2':
    digitar_medicoes()
else:
    print('Opção inválida.')

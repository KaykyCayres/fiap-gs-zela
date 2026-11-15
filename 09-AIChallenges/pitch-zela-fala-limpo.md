# Pitch da Zela (rascunho do texto de fala)

Só a fala, em ordem. Falta a parte da demonstração, que o grupo ainda vai definir.

## Abertura
Esse é o nosso projeto da Global Solution, a Zela, uma pulseira pra quem espera no pronto-socorro depois da triagem.

## Problema
Imagina que você chega ao pronto-socorro com falta de ar e febre. Passa pela triagem, recebe uma classificação e volta pra uma cadeira no corredor. A enfermeira sabe que você está ali, mas tem dezenas de pessoas pra cuidar. Você espera horas. E se, nesse meio tempo, você piorar? Ninguém vê. Só vão te chamar quando chegar a sua vez. A própria nota técnica do GBCR, de 2022, diz que a sala de espera deve ser tratada como área de observação. Só que não há uma maneira prática de observar.

## Público
Quem passa por isso é, muitas vezes, quem depende do SUS e espera por horas. Pode ser uma pessoa idosa, cansada, com dor, que não está em condição de mexer em celular ou aprender a usar um aplicativo. Então a gente pensou a solução pra essa pessoa. Ela não precisa fazer nada, não precisa de celular, nem de internet, nem de saber mexer em tela. Ela só usa a pulseira no pulso, e quem recebe o aviso é a equipe de enfermagem.

## Solução e ODS
A nossa solução é a Zela, uma pulseira com ESP32 que acompanha a pessoa enquanto ela espera. Ela mede a frequência cardíaca, a oxigenação e a temperatura, e classifica o paciente em três níveis, normal, atenção ou crítico. Quando algum sinal sai da faixa, ela avisa na hora, com luz e som, e a enfermagem vai reavaliar. A Zela não diagnostica nem decide nada, ela só chama quem decide. Assim, quem está esperando deixa de ficar sem ninguém olhando. O projeto se liga à ODS 3, saúde e bem-estar, na meta de saúde de qualidade e segura, e à ODS 10, redução das desigualdades, porque quem depende do SUS é quem mais sofre com a espera.

## Ideias da live
Pegamos várias dicas da live. A Maira, da Six, falou que o serviço só funciona quando a pessoa consegue resolver o que precisa sem sofrer pra isso. Ela nos deu três pilares como base, acesso, esforço e resolução, e a gente usou isso pra pensar na Zela. O paciente é acompanhado sem fazer nada, com esforço zero. E a enfermagem é avisada a tempo de agir. Também pensamos em quem vai usar, e por isso o paciente não precisa saber mexer em nada. O Ageu, da Claro, disse pra olhar como outros países resolveram o mesmo problema. Encontramos a Current Health, uma empresa escocesa que desenvolve um dispositivo vestível contínuo de sinais vitais com IA, usado para detectar mudanças no estado clínico de pacientes no hospital, depois da alta e em casa.

## Como construímos
Tudo começa no sensor. Um ESP32 lê temperatura, frequência cardíaca e saturação de oxigênio no sangue. A cada medição ele classifica a pessoa em normal, atenção ou crítico, e acende o LED e toca o buzzer. Esses mesmos limites estão no programa em Python e no banco de dados, onde uma trigger cria o alerta quando o nível piora. Assim as três partes falam a mesma língua. As leituras seguem por um CSV pro S3, que dispara uma Lambda que grava no banco na nuvem, e o CloudWatch registra tudo. Na estatística, olhamos dados reais de pessoas saudáveis junto com os nossos dados simulados e vimos que a pulseira poderia dar alarme falso. A conclusão foi que ela deveria confirmar a alteração em mais de uma leitura, e isso fica como melhoria. Com as medições, o machine learning e a rede neural tentam prever quem vai ficar crítico nos próximos 10 minutos. Usamos regressão logística comparada com uma árvore de decisão no machine learning, e duas MLP com números de neurônios diferentes na rede neural. Por fim, na segurança, validamos as leituras, conferimos o arquivo com hash e usamos um código no lugar do nome do paciente. Antes de programar, desenhamos a arquitetura e o UML, e foi aí que vimos que sensor, Python e banco precisavam usar os mesmos limites.

## Demonstração
(a definir pelo grupo)

## Gestão das entregas e fechamento
Pra organizar o trabalho, a gente montou um quadro no Trello, com um cartão por matéria e o checklist de cada enunciado dentro. Cada um ficou responsável por algumas matérias, e a gente sempre pedia a opinião de todos, pra todo mundo saber o que estava sendo feito em cada matéria. Quando alguém terminava, o cartão ia pra revisão, e outra pessoa conferia antes de ir pra feito. No GitHub, cada um fez commit da própria conta, documentando as mudanças em uma mensagem, então dá pra ver quem fez o quê. A maior dificuldade foi manter as partes alinhadas. O sensor, o Python e o banco precisavam usar os mesmos limites de normal, atenção e crítico, e a gente foi ajustando até os três bater. Isso ajudou a integrar as matérias, porque todo mundo trabalhou nos mesmos dados e no mesmo problema.
Pra fechar, pensamos nas condições reais de uso. A Zela é pensada pra ser acessível, porque o paciente não precisa de celular nem de saber mexer em tecnologia, e o aviso é por luz e som. Na segurança, validamos as leituras e conferimos o arquivo com hash. Na proteção de dados, o paciente aparece só por um código, nunca pelo nome. Pra sustentabilidade, a pulseira é reutilizável, com tira trocável, e o protótipo custa baixo. E a gente sabe o limite dela. É um protótipo, não diagnostica, e quem confirma é a enfermagem, com um aparelho certificado.

## Tela final
Nomes e RMs de todos, bem visíveis
Kayky Cayres Vicente da Silva, RM 575091
Naiara Sousa Soares, RM 574792
Rafael Medici, RM 576249

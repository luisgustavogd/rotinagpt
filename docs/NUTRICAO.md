# Cálculo de meta de proteína

Este documento explica de onde vem a sugestão automática de meta diária de
proteína (`ProteinTargetCalculator`, em
`lib/domain/profile/protein_target_calculator.dart`)
e como ela é usada no onboarding e na edição de perfil.

**O app não é um dispositivo médico.** A sugestão é um ponto de partida
baseado em literatura de nutrição esportiva — não substitui orientação de um
nutricionista ou médico, especialmente para quem usa medicação para perda de
peso (ex.: tirzepatida/Mounjaro) ou tem alguma condição de saúde.

## Referência

Jäger R, Kerksick CM, Campbell BI, et al. **International Society of Sports
Nutrition Position Stand: protein and exercise.** *Journal of the
International Society of Sports Nutrition.* 2017;14:20.
<https://pmc.ncbi.nlm.nih.gov/articles/PMC5477153/>

## Metodologia

O estudo recomenda faixas de proteína em gramas por kg de peso corporal por
dia, variando conforme o nível de atividade física e se a pessoa está em
déficit calórico:

| Nível de atividade | Faixa recomendada (g/kg/dia) | Ponto central usado pelo app |
| --- | --- | --- |
| Sedentário(a) | ~0,8 (RDA padrão) | 0,8 |
| Fisicamente ativo(a), sem déficit calórico | 1,4–2,0 | 1,7 |
| Em déficit calórico, com treino de força | 2,3–3,1 | 2,7 |

O app usa o **ponto central de cada faixa** multiplicado pelo peso atual do
usuário (mesmo padrão já usado para sugerir a meta de peso a partir do IMC
central — ver `lib/domain/profile/bmi_calculator.dart`). O usuário escolhe o
nível de atividade em um campo no onboarding/edição de perfil, e pode
sobrescrever o valor calculado a qualquer momento; a mensagem "valor
calculado baseado no estudo..." some assim que ele edita o campo
manualmente, mas o valor final continua exigindo validação profissional
(aviso fixo, sempre visível).

## Onde ficam as documentações do app

Este `docs/` é o lugar padrão para documentação do projeto que não caiba no
`README.md` (que fica com o essencial: stack, arquitetura, como rodar). Novas
referências, decisões de produto ou explicações de regra de negócio mais
longas devem virar um arquivo aqui, linkado a partir do README quando fizer
sentido.

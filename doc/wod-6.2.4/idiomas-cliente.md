# Idiomas do cliente: WoD 6.2.4.21742

Data: 2026-11-06.

## Estado da instalação

Opção A aplicada ao texto e à voz em ptBR no cliente local. Abaixo, a análise feita antes dela.

| Item | Resultado |
| --- | --- |
| Download do texto | 5.164 arquivos, 284 MiB, todos conferidos pelo MD5 do manifesto |
| Gravação no CASC | `data.031` novo e 16 `.idx` atualizados; leitura de volta sem erros |
| `mapextractor` (CascLib) | Reconhece `ptBR` e extrai 515 arquivos; `frFR` idêntico ao anterior |
| Servidor | `dbc/ptBR`, `DBC.Locale = 10`; sobe em ptBR |
| Voz | 37.065 arquivos, 1.025 MiB, em `data.031` e `data.032`; leitura de volta sem erros |
| Cliente com texto em ptBR | Abre; textos e mapa corretos no teste do usuário, em 2026-11-06 |
| Cliente com texto e voz em ptBR | Funcionou no Windows 11 (Parallels) e no CrossOver 22.1.1, segundo o teste do usuário em 2026-11-06 |
| Índices | Com texto e voz, o cliente falhou com `E_NOT_AVAILABLE` (até 32.654 entradas por bucket). Depois de remover as 41.147 entradas exclusivas de `frFR` (máximo de 30.072), voltou a abrir |
| Fechar o cliente | Congelou em testes anteriores; parou de congelar nos dois ambientes, sem causa identificada |

**Checksum B:** o cabeçalho de cada bloco tem dois checksums. O A é um `hashlittle` dos 22
primeiros bytes com a semente `0x3D6BE971`, conferido em blocos reais. A fórmula do B não
foi descoberta, então os blocos novos têm `0`. O CascLib ignora esse campo, e o
cliente abriu e exibiu os textos assim.

**Limite dos índices:** o valor exato não foi medido. Passou com até 30.299 entradas por
bucket e falhou com 32.654. Os dados de `frFR` continuam em `data.*`, mas fora dos índices.

**Voz:** o repack vinha com `Sound_EnableDialog = 0`, que desliga os diálogos falados.

Backups e ferramentas ficam em `server/locale-ptbr/`, fora do repositório.

## Análise inicial

Lista exata de arquivos: [`idiomas-arquivos.md`](idiomas-arquivos.md).

## Resposta curta

**Dá para ter enUS ou ptBR sem baixar o cliente inteiro e sem sair da build 21742.** O
manifesto da build já cataloga os dois idiomas, mas os dados não estão no disco. Faltam
cerca de 1,0 GiB (enUS) ou 1,3 GiB (ptBR), e só o texto são 162 ou 285 MiB. O que
falta provar é se o cliente aceita esses dados depois de adicionados.

## Perguntas

| Pergunta | Resposta | Evidência |
| --- | --- | --- |
| Existem arquivos enUS ou ptBR no CASC? | **Catalogados, sim; presentes, não** | Dos arquivos exclusivos desses idiomas no manifesto `download`, 0 estão no disco |
| Existem índices ou arquivos adicionais? | **Só de localização** | Os 386 `.index` da CDN estão em `Data/indices`, mas apontam para archives remotos; `Data/patch` está vazio |
| Dá para habilitar sem mudar a build? | **Não só pela configuração; sim adicionando os dados** | `Spell.dbc` e `GlobalStrings.lua` em ptBR e enUS estão no `root`, mas ausentes do disco |
| Dá para adicionar só o idioma? | **Provavelmente, falta testar** | Dados achados em espelhos, com amostras validadas por MD5 |
| O TrinityCore fornece as traduções? | **enUS, sim; ptBR, em parte** | Ver "Banco de dados" |

Isso também explica, muito provavelmente, por que o cliente não abre em `ptBR`: ele não
acha os dados. O motivo exato não foi testado.

## O que há no CASC

Build ativa: `WOW-21742patch6.2.4_Retail`, com etiquetas só de `frFR` no `.build.info`.

| Idioma | Exclusivos no manifesto | No disco | Tamanho |
| --- | --- | --- | --- |
| `enUS` | 41.702 | 0 | 1,02 GiB |
| `ptBR` | 42.229 | 0 | 1,28 GiB |

"Exclusivos" são os arquivos marcados para o idioma e não para `frFR`. Cada idioma
também compartilha com `frFR` 5.734 arquivos (cerca de 0,3 GiB) que o cliente atual não tem
e com os quais já funciona. Não sei o que são; não foram incluídos na conta.

### O que precisa ser adicionado

Os tamanhos incluem os arquivos soltos. Os 3 soltos do texto ptBR somam cerca de 105 MiB, e
não sei o que são.

| Pacote | Arquivos | Archives | Soltos | Tamanho |
| --- | --- | --- | --- | --- |
| `enUS` texto | 4.446 | 21 | 2 | 162 MiB |
| `enUS` voz | 37.256 | 17 | 0 | 887 MiB |
| `ptBR` texto | 5.164 | 22 | 3 | 285 MiB |
| `ptBR` voz | 37.065 | 8 | 0 | 1.025 MiB |

Só as partes necessárias dos archives seriam baixadas, por faixa de bytes.

### Build

Os arquivos são escolhidos por hash a partir do `root` da 21742, então nada de uma
6.2.3 entra no processo. O extrator detecta "21676" dentro dos arquivos, o que já constava
na auditoria e não muda isso.

## Onde os dados estão

| Origem | Situação |
| --- | --- |
| `blzddist1-a` e `blzddist2-a.akamaihd.net` (do `.build.info`) | 404 |
| `cdn.blizzard.com`, `us.cdn` e `eu.cdn` | 404 |
| `level3.blizzard.com` | 403 |
| `tact.mirror.reliquaryhq.com` | **Responde** |
| `cdn.arctium.tools` | Responde às configurações e a 4 archives de amostra |

No `reliquaryhq`, todos os archives e arquivos soltos da lista responderam. São espelhos de
terceiros, sem vínculo oficial, e podem sair do ar. A integridade dá para garantir, porque
cada arquivo é conferido pelo MD5 do manifesto.

Amostras baixadas para a memória, sem gravar em disco:

| Arquivo | Resultado | Texto |
| --- | --- | --- |
| `GlobalStrings.lua` ptBR | MD5 confere | `QUEST_LOG = "Mapa e Registro de Missões"` |
| `GlobalStrings.lua` enUS | MD5 confere | `QUEST_LOG = "Map & Quest Log"` |
| `Localization.lua` ptBR e enUS | MD5 confere | |

## Possibilidades

| | Opção | Download | Prós | Riscos |
| --- | --- | --- | --- | --- |
| **A** | Inserir o idioma no CASC local | 0,2 a 1,3 GiB | Resultado igual a um cliente normal; dá para validar com o extrator antes de abrir o jogo | Exige escrever uma ferramenta; não sei se o cliente aceita |
| **B** | Apontar `CDN Hosts` para o espelho e deixar o cliente baixar | Sob demanda | Só muda configuração | O executável consulta `patch.battle.net`, então é provável que falhe |
| **C** | Colocar o texto como arquivos soltos | Até 285 MiB | Sem mexer no CASC | Paliativo: é preciso sobrescrever arquivos em `frFR`, não muda a etiqueta do idioma, e a prioridade dos soltos não foi verificada |
| **D** | Baixar outro cliente completo | Cerca de 30 GiB | Nenhuma ferramenta | Difícil de achar; ainda exige o executável modificado |

### Arquivos soltos em francês

Vale para A, B e C. O repack traz arquivos que podem encobrir o novo idioma:

- `Interface/framexml/globalstrings.lua`, em francês.
- 40 `Localization.lua` em `Interface/AddOns/Blizzard_*`.
- `DBFilesClient/`, com `Spell.dbc`, `Item-sparse.db2`, `Map.dbc`, `ChrRaces.dbc` e outros.

Seria preciso trocá-los ou removê-los na cópia de teste. Isso também pode eliminar a
diferença entre cliente e servidor apontada em `servidor-local.md`. Remover `DBFilesClient`
pode afetar modificações do repack que não analisei.

## Banco de dados

### enUS

Nada a fazer: é o texto base das tabelas, com 22.263 quests e 77.012 criaturas.

### ptBR

| Conteúdo | Tabela | ptBR | Base |
| --- | --- | --- | --- |
| Falas e textos | `hotfixes.broadcast_text_locale` | 88.171 com texto | 89.715 |
| Quests | `world.quest_template_locale` | 18.054 | 22.263 |
| Objetivos de quest | `world.quest_objectives_locale` | 6.378 | Não contado |
| **Nomes de criaturas** | `world.creature_template_locale` | **0** | 77.012 |
| **Nomes de objetos** | `world.gameobject_template_locale` | **0** | Não contado |
| Páginas e pontos de interesse | `page_text_locale`, `points_of_interest_locale` | 0 | Não contado |
| Mensagens do servidor | `world.trinity_string` | **Sem coluna ptBR** | 1.039 |

- **Quests:** 2.991 das 18.054 têm o mesmo título em inglês. A amostra inclui itens
  `[DEPRECATED]`, então parte nem deve aparecer no jogo.
- **Falas:** 12.507 de 12.998 `creature_text` e 3.921 de 5.348 opções de gossip usam
  `BroadcastText`, portanto podem aproveitar o texto em ptBR.
- **Sem tradução:** o que falta aparece em inglês; `GetBroadcastTextValue` faz isso nas
  falas. Não conferi as outras tabelas no código.
- **Magias, itens e interface:** vêm dos arquivos do cliente, não destas tabelas.

### Como completar os nomes em ptBR

Isso cobre pouco. O `Creature.db2` tem só 5.249 registros, porque o restante dos nomes
vinha do servidor da Blizzard. Validei os IDs contra o francês já presente no banco: 288 de
293 criaturas e 1.911 de 1.977 objetos batem.

Aplicado no banco local e em `docker/sql-init/03-ptbr-names.sql`: 5.241 de 77.012 criaturas
e 2.347 objetos. **Os demais nomes ficam em inglês.**

### Mudanças no servidor

1. Extrair os dados do novo idioma para `data/dbc/ptBR` ou `enUS`. Isso depende da opção A
   ou D, porque o extrator lê do CASC local.
2. Usar `DBC.Locale = 10` (ptBR) ou `0` (enUS).

**Testar em ptBR:** `DB2Stores.cpp:205` usa a máscara `0xFF`, que não alcança o ptBR
(índice 10). Por isso ele precisa ser o idioma principal para os DB2 serem lidos dos
arquivos. As traduções do banco carregam de qualquer forma. O código também espera texto em
`Str[DEFAULT_LOCALE]`, que é o enUS, e não testei o efeito disso com `DBC.Locale = 10`.

## Recomendação

Opção **A**, em duas etapas, com a cópia em `C:\Games\WoW624` para teste e a pasta do Mac
como original:

1. **ptBR só com texto (285 MiB)**, mantendo a voz em francês. Se o cliente não aceitar, a
   perda é pequena.
2. **Voz, se o texto funcionar:** ptBR (1.025 MiB) ou enUS (887 MiB).

Critérios de aceite, em ordem:

1. O `mapextractor` detecta o `ptBR` e extrai os DBC.
2. O cliente abre com `textLocale` em `ptBR`.
3. Login, personagem e mundo funcionam como hoje.
4. Quests e falas aparecem em português.

Se a etapa 1 falhar no cliente, o caminho é a opção D, e o enUS passa a ser mais realista.

## Limites desta análise

- Os resultados vêm dos manifestos da build; nenhuma instalação foi testada.
- A escolha do cliente entre soltos e CASC não foi verificada.
- A compatibilidade do executável `modcraft` com outro idioma não foi testada. Ele contém
  as strings `ptBR` e `enUS`, o que não prova nada sozinho.
- Os totais de "voz" e "texto" seguem as etiquetas do manifesto `download`.

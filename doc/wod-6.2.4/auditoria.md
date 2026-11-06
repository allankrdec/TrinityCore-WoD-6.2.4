# Auditoria: WoD 6.2.4.21742 (Etapas 1 e 2)

Data: 2026-11-05. warcraft-rs `76bedfd` (0.7.0), cascette-rs `2d1294b`.
Nenhum parser foi alterado nesta etapa.

> Esta auditoria trata do warcraft-rs, uma ferramenta externa de leitura de arquivos.
> Ela não altera o servidor. Os caminhos `tools/casc-probe` e `compose.yaml` citados
> aqui ficam no clone local `wow-6.2.4/warcraft-rs`, fora deste repositório.

## Conclusões

- **CASC é viável com o cascette-rs**, usando somente a API de baixo nível.
  Os atalhos por caminho e por FileDataID não funcionam em uma instalação real.
- **O suporte a 6.2.4 não está completo.** O README do `wow-m2` declara "WoD 6.2.x
  Full", mas 82 de 171 modelos reais falham (48%).
- **Encontrei um defeito com causa provável:** a flag de high-res holes do ADT
  está errada e pode também gerar dados incorretos sem erro.
- **Os testes atuais não cobrem nada disso.** A baseline passa inteira porque o
  repositório quase não usa arquivos reais.

## Como foi medido

| Item | Valor |
| --- | --- |
| Ambiente | Docker, Linux aarch64, Rust 1.92 |
| Cliente | `.build.info` e executável `6.2.4.21742`, `WOW-21742patch6.2.4_Retail`, frFR, repack |
| Acesso ao cliente | Montagem somente leitura |
| Validação de leitura | MD5 do arquivo decodificado comparado com a content key |
| Baseline, features padrão | 46 suítes: 1439 aprovados, 0 falhas, 49 ignorados |

Limites da medição:

- "OK" na tabela de formatos significa que o comando `info` terminou sem erro.
  Não prova que os valores estão corretos.
- As texturas BLP não foram decodificadas, só os cabeçalhos.
- Nada foi comparado ainda com ferramentas de referência (Etapa 4).
- A amostra é pequena: 3000 registros espaçados de um total de 874.666.

## CASC

| Etapa | Resultado em 6.2.4 |
| --- | --- |
| `.idx` (versão 7) e archives | 16 índices, 474.561 entradas, 31 archives |
| `encoding` | 52.640.302 bytes, MD5 correto |
| `root` | V1, 24.497.536 bytes, MD5 correto, 574 blocos, 874.666 registros |
| Arquivos nomeados | 23 de 23 lidos com MD5 correto, escolhendo a variante do locale |
| Amostra | 1789 corretos, 0 divergências de MD5, 1211 não encontrados |

As 1211 ausências combinam com uma instalação de um único locale, mas não foram
checadas uma a uma. No 7.3.5, verifiquei uma chave ausente: ela não estava em
nenhuma geração de `.idx`.

### Limitações do cascette-rs nesta revisão

| Problema | Evidência | Como contornar |
| --- | --- | --- |
| `read_file_by_content_key` busca a content key em índices organizados por encoding key | `installation.rs:115`; falhou nos dois clientes testados | Resolver pelo `encoding` e usar `read_file_by_encoding_key` |
| `read_file_by_path` e `read_file_by_fdid` dependem dessa função | `installation.rs:300` e `:334` | O mesmo |
| A resolução por caminho ignora o locale | `Map.dbc` tem 11 variantes, só frFR (`0x10`) está instalada, e o resolver escolheu outra | Usar `RootFile::get_entries_by_path` e filtrar o locale |
| `get_file_info` não normaliza o caminho | Só encontrou caminhos em maiúsculas e com `\` | Normalizar antes da chamada |
| `load_all` não compara a versão dos `.idx` | Há duas gerações por bucket; a última lida vence. Aqui foi a mais nova, mas isso depende da ordem do diretório | Corrigir no cascette ou carregar os índices na integração |
| O cache de leitura não tem limite | `installation.rs` guarda todo arquivo lido | Evitar leituras em massa pela `Installation`, ou limpar o cache |
| Imprime `DEBUG:` em stdout | Saída da sonda | Filtrar |
| Não está no crates.io | A API do crates.io responde que os crates não existem | Dependência git fixada; ajustar `allow-git` no `deny.toml` |

### Recomendação

Criar um crate novo e opcional, `wow-casc`, que encapsule o cascette-rs fixado em
uma revisão e resolva locale, normalização e leitura por encoding key. Os crates
de formato continuam recebendo bytes e não ganham dependência nova. Vale também
reportar os defeitos acima ao projeto cascette-rs.

## Formatos em arquivos reais

Valores brutos lidos por um script independente dos parsers:

| Formato | Versão real | warcraft-rs hoje | OK | Problema observado |
| --- | --- | --- | --- | --- |
| DBC | `WDBC` | Lê | 2 de 2 | Sem validação de campos |
| DB2 | `WDB2`, build interno 21676 | Lê | 4 de 4 | Ver abaixo |
| BLP | `BLP2` | Lê cabeçalho | 823 de 823 | Decodificação não testada |
| M2 | `MD20`, versão 272 | **Falha em parte** | **89 de 171** | Causa desconhecida |
| SKIN | `SKIN` | Lê | 175 de 175 | Rotulado "Old (WotLK and earlier)" |
| WMO | `MVER` 17 | Lê | 76 de 76 | README diz versão 20 para WoD |
| ADT raiz | `MVER` 18 | **Falha em parte** | **46 de 48** | Flag errada |
| ADT `_tex` | `MVER` 18 | Lê | 77 de 77 | Rotulado Cataclysm ou MoP |
| ADT `_obj` | `MVER` 18 | Lê | 41 de 41 | Rotulado Cataclysm |
| WDT | `MVER` 18 | Lê | 2 de 2 | `MPHD` e `MAIN` apenas |
| WDL | `MVER` 18 | Lê | 4 de 4 | Rotulado "Wrath of the Lich King" |

As linhas de DBC, DB2 e WDT vêm de arquivos nomeados, e a de WDL soma 2 nomeados
e 2 da amostra. As demais vêm da amostra. Além disso, os dois ADTs raiz nomeados
(`Azeroth_32_48`, `Draenor_32_32`) e `HumanMale.m2` também falham.

### ADT: flag de high-res holes

- `wow-adt` testa `0x200` (`chunks/mcnk/header.rs:68`).
- O extrator do TrinityCore testa `0x10000` (`map_extractor/System.cpp:618`), com
  o campo em união com `HighResHoles` (`adt.h:107`).
- Os MCNK que falham têm flags `0x18001`, e os bytes dos buracos (`0xf0f0`,
  `0x307`) acabam interpretados como offset do MCVT.
- Na amostra, as 2 falhas estão entre os 15 ADTs com a flag `0x10000`. Nenhum dos
  33 sem ela falhou.
- Os testes unitários usam o mesmo `0x200`, por isso passam.

**Risco:** um valor de buraco pode apontar para um local legível e o parse terminar
sem erro, com alturas erradas. Nos ADTs nomeados, MCNKs com buracos anteriores ao
ponto de falha não causaram erro, então os 13 ADTs com a flag que passaram não são
confiáveis. A causa só fica confirmada depois de corrigir e medir novamente. A
correção também afeta MoP e precisa de teste de regressão.

### DB2

- Os registros de `Item-sparse.db2` começam no lugar certo: o primeiro ID é 17, igual
  a `min_index`, com tabela de índice presente.
- O tamanho de todos os arquivos bate com o cabeçalho de 48 bytes mais as tabelas.
- A CLI mostra `Magic: WDBC` em arquivos `WDB2` e calcula o tamanho total errado.
- `CriteriaTree.db2` tem 8 campos em 40 bytes. O formato do TrinityCore
  (`niliiisi`) contém um campo de 64 bits, então a exibição como campos de 4 bytes
  está incorreta para essa tabela.
- `Wdb2Header` usa `max_index > 0`, enquanto o TrinityCore usa `!= 0`.
- Os comentários de `DbcVersion` associam `WDB3`, `WDB4` e `WDB5` a expansões
  antigas. Isso contradiz o 6.2.4, cujos arquivos medidos e cujo carregador usam
  somente `WDB2`.

### Detecção de versão

Os arquivos não permitem identificar WoD de forma confiável:

- O `MVER` é o mesmo das versões anteriores, segundo o próprio código do warcraft-rs.
- `M2Version::from_header_version(272)` retorna Cataclysm e `to_header_version` de
  WoD retorna 275, marcado no código como teórico. O valor real é 272.
- `AdtVersion::detect_from_chunks` nunca retorna WoD, e `converter.rs` cita variantes
  que não aparecem no enum atual.
- `version_detection.rs` afirma que o `GFID` surgiu no 6.2.4, mas nenhum dos 17 WMOs
  raiz da amostra tem esse chunk.

A proposta é a versão ser informada pelo chamador, em vez de presumida pelo conteúdo.

## Mudanças de MoP 5.4.8 para WoD 6.2.4

| Área | Mudança | Fonte |
| --- | --- | --- |
| Contêiner | MPQ para CASC, com root V1 | Cliente real |
| Tabelas | 61 tabelas passam de DBC para DB2 | Fontes dos servidores |
| Tabelas | 32 só em MoP, 56 só em WoD | Fontes dos servidores |
| Campos | 93 de 150 tabelas em comum mudam a string de formato; 34 mudam a contagem de campos | Fontes dos servidores |
| ADT | `_obj0`, `_obj1`, `_tex0` e `_tex1` presentes; `_lod` ausente em `Azeroth_32_48` | Cliente real |
| M2 e WMO | Sem diferença de cabeçalho nos extratores | Fontes dos servidores |

Essas comparações usam `pandaria_5.4.8` e `TrinityCore-WoD-6.2.4`, que são projetos
diferentes. Elas só cobrem o que os servidores carregam, e parte das diferenças de
formato pode ser só de declaração. Ainda não comparei arquivos reais de MoP com os
de WoD.

## Ainda não compreendido

- **M2:** a causa das 82 falhas. Os offsets do cabeçalho de `HumanMale.m2` são válidos
  e o erro não indica o campo. A flag `0x10` aparece em 31 de 32 modelos com ela
  falhando, mas 51 falhas ocorrem sem ela, então não explica tudo.
- **`MAOI` e `MAOH`:** 3 arquivos da amostra têm só esses chunks e `MVER`.
- **Assinaturas fora do escopo:** `SYHP`, `RVXT`, `HSXG` e `worl` apareceram na amostra
  e não foram analisadas.
- **`MBMI`, `MBBB`, `MBMH`, `MBNV`:** presentes em 3 ADTs raiz, sem verificação de
  como o parser os trata.

## Cuidados com este cliente

- **Arquivos soltos diferem do CASC.** `DBFilesClient/` tem 60 arquivos, e os 4 que
  comparei têm tamanho e MD5 diferentes da versão no CASC. Os testes devem declarar a
  origem, e a referência proposta é o CASC.
- **Build nos arquivos:** o cabeçalho dos DB2 traz 21676, não 21742. Um teste não
  deve exigir 21742 nesse campo.
- **Build no TrinityCore:** `auth_database.sql` usa 21742, mas `RealmList.cpp:203`
  lista só 21355 para 6.2.4. Não alterei isso.

## Defeito de ambiente

`wow-mpq` não compila em aarch64 com `--features simd` (e portanto com
`--all-features`): falta importar `is_aarch64_feature_detected` e o módulo
`crypto::keys` é privado. O padrão não é afetado.

## Plano proposto para a Etapa 3

A ordem pedida é mantida, com o CASC antes por ser pré-requisito dos testes:

1. **`wow-casc`:** leitura por caminho e locale, com os testes de MD5.
2. **DBC/DB2:** corrigir a CLI, tratar campos de 64 bits e validar esquemas.
3. **BLP:** decodificar todas as combinações encontradas na amostra.
4. **M2:** diagnosticar as falhas, corrigir e ajustar o mapeamento da versão 272.
5. **WMO:** corrigir README e detecção, e validar a geometria.
6. **ADT:** corrigir a flag, testar MoP e WoD, e medir novamente.
7. **WDT e WDL:** corrigir rótulos e validar o conteúdo.

## Como reproduzir

```bash
WOW_CLIENT_DIR="/caminho/do/cliente" docker compose run --rm \
  -e CARGO_TARGET_DIR=/cargo-target/probe dev sh -c \
  'cd tools/casc-probe && cargo run --release -- /wow/client --sample 3000 \
   "World/Maps/Azeroth/Azeroth.wdt"'
```

`tools/casc-probe/scripts/` contém os scripts de classificação e medição. Arquivos do
jogo não são versionados.

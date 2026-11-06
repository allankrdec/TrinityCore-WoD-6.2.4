# Extração de dados: WoD 6.2.4.21742

Data: 2026-11-05. Cliente frFR, repack, montado como somente leitura.
Nenhum arquivo do repositório foi alterado para compilar ou extrair.

## Resultado

| Etapa | Ferramenta | Tempo | Resultado |
| --- | --- | --- | --- |
| DBC, DB2 e maps | `mapextractor` | 3 min | 515 arquivos (202 MB), 11.934 `.map` (553 MB) |
| Extração de vmaps | `vmap4extractor` | 20 min | 15.869 arquivos (614 MB), `No errors` |
| Montagem de vmaps | `vmap4assembler` | 10 min | 22.451 arquivos (1,2 GB), `Ok, all done` |
| mmaps | `mmaps_generator` | Só amostra | Ver abaixo |

Os dados ficam fora do repositório, em `server/data/`. `Buildings/` é intermediário:
o servidor usa `dbc/`, `maps/`, `vmaps/` e, se ativado, `mmaps/`.

## Conferências

- **DBC/DB2:** os 212 arquivos referenciados em `src/server/game/DataStores` existem
  em `dbc/frFR/`. Isso compara só nomes. O formato de cada tabela só é validado quando
  o servidor os carrega.
- **Ausentes no cliente:** 58 arquivos pedidos pelo `mapextractor` não existem no CASC
  (por exemplo `DeclinedWord` e vários `gt*`). Nenhum está entre os 212.
- **Assinatura de mapa:** `v1.8` no extrator e em `Map.cpp`, conferida no código.
- **Build detectado:** 21676 nos arquivos, como já visto na auditoria.

## Pendências

- **75 `.wdt` não abriram no `vmap4extractor`.** A maioria é de transportes e mapas de
  teste, mas a lista inclui nomes como `StormwindPrison`, `Sunwell5Man`,
  `TheBattleforGilneas` e `DarkmoonCarousel`. Esses mapas não têm vmaps. Não verifiquei
  se o servidor os usa. Lista: `grep "Can't open" tools-docker/extract-vmap.log`.
- **4 modelos `.m2` referenciados não abriram.** O impacto não foi avaliado.
- **Tabelas soltas do repack diferem do CASC.** O extrator lê só o CASC. Ver
  `servidor-local.md`.

## mmaps

Não foram gerados por completo. `mmap.enablePathFinding` já é `0` em
`worldserver.conf.dist`, então o servidor não depende deles para subir.

| Amostra | Tempo | Saída |
| --- | --- | --- |
| Mapa 566 inteiro (36 arquivos `.map`) | 594 s | 10 `.mmtile` |
| Mapa 0, bloco 32,32 | 40 s | 1 `.mmtile` |

Isso dá de 16 a 40 s por bloco, com 11.934 blocos e 3 threads: **de 18 a 44 horas, como
piso.** A amostra é pequena e tem pouca geometria, e blocos densos de continente devem
levar bem mais. Numa máquina x86 nativa deve ser bem mais rápido, mas isso não foi medido.

## Ambiente

Os arquivos ficam em `server/tools-docker/`, fora do repositório.

| Decisão | Motivo |
| --- | --- |
| `linux/amd64`, emulado no Apple Silicon | `common` usa SFMT com SSE2 e o G3D tem assembly x86; ARM exigiria alterar o código |
| Ubuntu 16.04 (Boost 1.58, GCC 5.4) | No 20.04, o Boost 1.71 mudou `asio::strand` e a glibc define `CHAR_WIDTH`, quebrando o código de 2016 |
| `DEBIAN_FRONTEND=noninteractive` | Sem isso o `tzdata` trava o build pedindo o fuso horário |
| Base `trinity-base-amd64` marcada localmente | O builder clássico ignora `--platform` quando há base arm64 em cache |
| Cópia de `.build.info` montada sobre o original | `CascFiles.cpp:923` abre esse arquivo com `O_RDWR` só para testar se existe, o que falha em montagem somente leitura e aparece como `FILE_NOT_FOUND` |

## Como reproduzir

```bash
cd server/tools-docker
./build.sh
C=/caminho/do/cliente; D="$(cd ../data && pwd)"
cp "$C/.build.info" build.info.copy
RUN="docker run --rm --platform linux/amd64 -v $C:/client:ro \
  -v $PWD/build.info.copy:/client/.build.info -v $D:/data \
  -v trinity-tools-amd64:/build -w /data trinity-tools /build/src/tools"
$RUN/map_extractor/mapextractor -i /client -o /data
$RUN/vmap4_extractor/vmap4extractor -d /client
mkdir -p "$D/vmaps"
$RUN/vmap4_assembler/vmap4assembler Buildings vmaps
```

Se o caminho do cliente tiver espaços, ajuste as aspas.

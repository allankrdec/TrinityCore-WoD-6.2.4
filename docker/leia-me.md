# Servidor WoD 6.2.4.21742 em Docker

Para Linux `x86_64`. Instalado no mini PC Debian 12; ver "Estado" no fim.

## Portas

| Porta | Uso |
| --- | --- |
| 1119, 8081 | `bnetserver` |
| 8085, 8086 | `worldserver` |

O banco não publica nenhuma porta. O servidor 5.4.8 também usa a 8085, então os dois não
sobem juntos sem mudar a porta de um deles.

Compilar e importar o banco não exigem parar o 5.4.8. Só pare antes do passo 5, na pasta
do `docker-compose.yml` dele:

```bash
docker compose down      # sem -v, para manter o banco
```

Use `down`, não `stop`: com `restart: always`, um contêiner só parado volta a subir quando
o Docker ou a máquina reiniciam.

## Instalação

### 1. Copiar os arquivos

No Mac, a partir da pasta `server/`, trocando `MINI_PC` pelo IP do mini PC:

```bash
rsync -av --exclude .git --exclude build --exclude .DS_Store \
  TrinityCore-WoD-6.2.4/ wow@MINI_PC:~/wod/
rsync -av data/dbc data/maps data/vmaps wow@MINI_PC:~/wod/docker/data/
rsync -av tdb/TDB_full_6.04_2016_04_11/*.sql wow@MINI_PC:~/wod/docker/tdb/
```

O `docker/tdb/` precisa ter os dois `.sql` da TDB 6.04 **antes** da primeira subida.

### 2. Configurar

No mini PC:

```bash
cd ~/wod/docker
cp .env.example .env
nano .env      # SERVER_IP = IP do mini PC
```

`DBC.Locale` em `etc/worldserver.conf` precisa bater com a pasta em `data/dbc/`
(`2` = `frFR`, `0` = `enUS`, `10` = `ptBR`).

### 3. Compilar

```bash
docker compose build
```

Compila servidores e ferramentas. Em caso de falta de memória, reduza o `-j"$(nproc)"`
no `Dockerfile`.

### 4. Criar o banco

```bash
docker compose up -d db
docker compose logs -f db      # esperar "import: ALL DONE" e depois "ready for connections"
```

A importação roda uma única vez. Se falhar no meio, apague o banco e repita:
`docker compose down -v`. **Esse comando apaga contas e personagens.**

### 5. Subir

```bash
docker compose up -d
docker compose logs -f worldserver      # esperar "ready..."
```

Na primeira subida, o `worldserver` aplica os updates de `sql/updates`.

### 6. Criar a conta

```bash
docker attach wow-wod-world      # sair com Ctrl+P Ctrl+Q
```

```
bnetaccount create email@exemplo.com senha
account set gmlevel 1#1 3 -1
```

O nome precisa ter `@`. `1#1` é a conta de jogo da primeira conta criada; só use a segunda
linha se ela for GM.

### 7. Configurar o cliente

No `WTF/Config.wtf`, com o IP do `.env`:

```
SET portal "IP_DO_MINI_PC"
SET realmlist "IP_DO_MINI_PC"
```

Rode o cliente de um disco local do Windows, não de uma pasta compartilhada.

## Arquivos SQL

| Pasta | Quando roda | Para quê |
| --- | --- | --- |
| `docker/sql-init/` | Uma vez, na criação do banco, em ordem alfabética | Dados da instalação |
| `sql/custom/world`, `auth`, `characters`, `hotfixes` | Ao iniciar o `worldserver`, uma vez por arquivo | Mudanças depois de instalado |

### Na instalação

Coloque o arquivo em `docker/sql-init/` antes do passo 4, com nome posterior a
`03-ptbr-names.sql`, e inicie com `USE world;` (ou o banco desejado). Ele só roda com o
banco vazio. Com o banco já criado, use `sql/custom/`.

### Depois de instalado

Coloque o arquivo na pasta do banco, com nome no formato `AAAA_MM_DD_NN_banco.sql`:

```bash
nano ../sql/custom/world/2026_11_06_00_world.sql
docker compose restart worldserver
```

O log mostra `Applying update`, e o arquivo fica registrado na tabela `updates` do banco, o
que evita rodar de novo. Não use `USE` nesses arquivos.

Um arquivo já aplicado não deve ser editado: faça um novo com a correção.

## Gerar os mmaps (opcional)

Sem eles, as criaturas não usam pathfinding. O servidor pode continuar no ar:

```bash
mkdir -p data/mmaps
docker compose run -d --name wow-wod-mmaps --no-deps -w /app/data \
  worldserver /app/bin/mmaps_generator --threads 4
docker logs -f wow-wod-mmaps
```

Ao terminar, use `mmap.enablePathFinding = 1` em `etc/worldserver.conf`, depois:

```bash
docker rm wow-wod-mmaps
docker compose restart worldserver
```

## Se o `worldserver` cair ao carregar os DB2

No Mac, em emulação, ele caía em `malloc` nesse ponto. Se acontecer aqui também, adicione
em `environment` do `worldserver`, em `docker-compose.yml`:

```yaml
      MALLOC_CONF: tcache:false
```

Detalhes em `doc/wod-6.2.4/servidor-local.md`.

## Publicar a imagem

```bash
docker push allankrdec/wow-wod-6.2.4
```

Depois disso, outra máquina pode usar `docker compose pull` no lugar do passo 3.

## Estado

Instalação do zero em 2026-11-06: Debian 12, 4 núcleos, 16 GB de RAM.

| Item | Resultado |
| --- | --- |
| `docker compose build` | 16 min, sem erros |
| Importação do banco | Cerca de 30 s |
| Primeira subida do `worldserver` | 12 s, 1,28 GB de RAM, sem `MALLOC_CONF`; mais 3 reinícios sem queda |
| Portas, vistas da rede | 1119, 8081, 8085 e 8086 abertas; 3306 fechada |
| Login REST | Senha certa recebe ticket, senha errada não |
| Aplicação de `sql/custom` | Verificada no servidor local, não nesta instalação |
| **Cliente no mini PC** | **Não testado** |
| **Geração completa dos mmaps** | **Não testada** |

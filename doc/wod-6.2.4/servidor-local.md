# Servidor local: WoD 6.2.4.21742

Data: 2026-11-06. Ambiente de teste no Mac, em Docker (`linux/amd64` emulado).
Nenhum arquivo de código do repositório foi alterado.

## Estado

| Item | Resultado | Como foi verificado |
| --- | --- | --- |
| Compilação | `worldserver` e `bnetserver` sem erros, em 1h58 | `build-server.log` |
| Bancos | `auth` 26, `characters` 111, `hotfixes` 154, `world` 172 tabelas | Consulta no MySQL |
| Conteúdo | 77.012 criaturas, 204.984 spawns, 22.263 quests, TDB 6.04 | Consulta no MySQL |
| Atualizações SQL | Aplicadas pelo `worldserver` na primeira subida | Log e tabela `updates` |
| `worldserver` | `ready...` em cerca de 80 s, 1,3 GB de RAM | Log |
| Login | Senha certa recebe ticket, senha errada não | POST em `:8081/bnetserver/login/` |
| Portas | 1119, 8081, 8085 e 8086 abertas; TLS em 1119 | `nc`, `openssl` |
| Cliente conectando | Login, reino, criação de personagem e entrada no mundo funcionaram | Teste do usuário em 2026-11-06, Windows 11 no Parallels, cliente frFR |

## Como usar

```bash
cd server/tools-docker/run
docker compose up -d
docker compose logs -f worldserver     # esperar "ready..."
docker attach wow-wod-world            # console; sair com Ctrl+P Ctrl+Q
docker compose down                    # parar, mantendo o banco
```

Conta de teste: `admin@admin.com`, senha `admin`, nível GM 3.

Comandos não interativos: `python3 run/console.py 'server info'`.

### Cliente

O servidor está configurado para `192.168.1.150`, e o cliente roda em outra máquina da
rede:

1. No `WTF/Config.wtf` do cliente, use `SET portal "192.168.1.150"` e
   `SET realmlist "192.168.1.150"`.
2. Inicie pelo `start-64.bat`.
3. Entre com o e-mail e a senha acima.

Se o IP do servidor mudar:

1. Em `run/etc/bnetserver.conf`, ajuste `LoginREST.ExternalAddress` e
   `LoginREST.LocalAddress`.
2. Atualize o banco:
   `UPDATE auth.realmlist SET address='NOVO_IP', localAddress='NOVO_IP';`
3. Reinicie com `docker compose restart bnetserver worldserver`.

Os dois endereços ficam iguais porque, com o Docker publicando as portas, o servidor pode
ver o cliente pelo IP interno da rede do Docker, e não pelo IP real.

Não rode o cliente de uma pasta compartilhada do Parallels: ele falha com `The CAS system
was unable to initialize`. Copiado para o disco do Windows, o mesmo cliente abriu.

## Problemas conhecidos

### Queda no `malloc` sob emulação

Sem ajuste, o `worldserver` cai ao carregar os DB2 com `SIGSEGV` em `malloc`
(`0x2232fda`). O contador `ncached` do cache do jemalloc estava em `0xfbffff`.

| Teste | Resultado |
| --- | --- |
| Sem ajuste | Caiu em todas as subidas diretas (só 1 execução de depuração passou) |
| `MALLOC_CONF=lg_dirty_mult:-1` | 4 quedas em 4, hipótese do `madvise` descartada |
| `MALLOC_CONF=tcache:false` | 4 subidas completas em 4 |
| `tcache:false,redzone:true,junk:true` | Sobe, sem relato de corrupção |

**Paliativo no Mac:** `MALLOC_CONF=tcache:false` em `run/docker-compose.yml`.

**Em x64 real, a queda não aparece:** no mini PC, o `worldserver` subiu 4 vezes em 4 sem o
ajuste, com a mesma base de código. Isso aponta para a emulação, sem provar a causa exata.

**Causa não confirmada.** Os testes apontam para o cache do jemalloc sob emulação, mas
não eliminam um bug real: o `redzone` só detecta escritas vizinhas ao bloco, e
`LoadStrings` (`DB2StorageLoader.cpp:667`) não checa o limite do índice.

### Tabelas soltas do repack diferem do CASC

47 dos 60 arquivos em `DBFilesClient/` diferem do CASC, vários com mais registros:

| Arquivo | Solto | CASC |
| --- | --- | --- |
| `CharBaseInfo.dbc` | 188 | 122 |
| `CharStartOutfit.db2` | 374 | 218 |
| `Talent.dbc` | 350 | 309 |
| `ChrSpecialization.dbc` | 42 | 40 |
| `SpellEffect.dbc` | 184.682 | 183.794 |

As datas dos que conferi vão de 2017 a 2024, o que sugere modificações do repack. O
executável também é modificado (`Wow-64-modcraft.exe`). O servidor usa o CASC, que é o
que o extrator lê. Não verifiquei se o cliente prioriza os arquivos soltos, mas, se
priorizar, as duas versões divergem.

**Se a criação de personagem, os talentos ou as magias parecerem errados, comece por
aqui.** Trocar para os arquivos soltos é possível, mas a TDB não foi feita para eles.

### Erros de dados

Cada subida registra cerca de 9.800 linhas em `DBErrors.log`. Os maiores grupos:

| Quantidade | Erro | Observação |
| --- | --- | --- |
| 1.943 | Facção inexistente | Todas com valor `0`, entradas 89348 a 97240 |
| 1.294 | Modelo inexistente | 733 IDs entre 61699 e 65128, ausentes do `CreatureDisplayInfo` |
| 1.307 | `quest_poi` sem quest | |
| 778 | Loot de gameobject inexistente | |
| 698 | Quest com magia de recompensa inexistente | |

As criaturas clássicas que conferi têm facção e modelo normais. Não analisei o efeito
no jogo, nem comparei com o volume normal de erros da TDB 6.04.

### Outros

- **mmaps** não gerados; `mmap.enablePathFinding = 0`. Ver `extracao.md`.
- **Mapas sem vmaps:** 75 `.wdt` não abriram. Ver `extracao.md`.
- **Build 21742:** não está em `RealmList.cpp:203`, mas o `else` em `:257` e `:313`
  responde com 6.2.4 e o build do banco. Isso vem da leitura do código; a confirmação é
  o cliente conectar.
- **Avisos no `.conf`:** faltam `MonsterSight`, `GuarderSight`, `Guild.SaveInterval` e
  `Guild.UndeletableLevel`; o servidor usa os valores padrão.
- **Versão exibida:** `rev. unknown`, porque o build usa `WITHOUT_GIT=1`.

## Decisões do ambiente

| Decisão | Motivo |
| --- | --- |
| `mysql:5.7` com `--sql-mode=NO_ENGINE_SUBSTITUTION` | Dumps de MariaDB 10.1, código de 2016 |
| Usuário `trinity@'%'` | Os servidores conectam de outros contêineres |
| Porta 3306 só em `127.0.0.1` | Não precisa de acesso externo |
| `--innodb_flush_log_at_trx_commit=2` | Importação mais rápida, adequado só para teste |

## Arquivos

Tudo fora do repositório, em `server/`:

| Caminho | Conteúdo |
| --- | --- |
| `tools-docker/build.sh`, `build-server.sh` | Compilação |
| `tools-docker/run/` | `docker-compose.yml`, `etc/`, `logs/`, `sql-init/`, `console.py` |
| `data/` | `dbc`, `maps`, `vmaps`, `Buildings`, amostra de `mmaps` |
| `tdb/` | TDB 6.04 oficial |

Volumes do Docker: `trinity-server-amd64` (binários), `trinity-tools-amd64`
(extratores) e `wow-wod-db` (banco).

## Para a produção

O pacote está em `docker/`, no modelo de `allankrdec/pandaria_5.4.8/docker`. O passo a
passo e o que falta testar estão em `docker/leia-me.md`.

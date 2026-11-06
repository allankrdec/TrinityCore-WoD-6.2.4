# Build from the repository root: docker compose -f docker/docker-compose.yml build
# Ubuntu 16.04 on purpose (Boost 1.58, GCC 5.4): newer Boost and glibc break this 2016 code.

# -------- STAGE 1: BUILD --------
FROM ubuntu:16.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential cmake git ca-certificates \
       libboost-all-dev libssl-dev libbz2-dev zlib1g-dev \
       libmysqlclient-dev libreadline-dev libncurses-dev \
    && rm -rf /var/lib/apt/lists/*

COPY . /src

WORKDIR /build

RUN cmake /src \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/app \
      -DSERVERS=1 \
      -DTOOLS=1 \
      -DSCRIPTS=static \
      -DWITHOUT_GIT=1 \
    && make -j"$(nproc)" \
    && make install

# -------- STAGE 2: RUNTIME --------
FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       libboost-filesystem1.58.0 libboost-iostreams1.58.0 \
       libboost-program-options1.58.0 libboost-regex1.58.0 \
       libboost-system1.58.0 libboost-thread1.58.0 \
       libmysqlclient20 libreadline6 libssl1.0.0 zlib1g \
       mysql-client-5.7 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app /app
# The database updater reads sql/updates from here (SourceDirectory in the .conf files).
COPY sql /app/sql
COPY docker/start.sh /app/start.sh

WORKDIR /app

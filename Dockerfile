# ターミナルから直接実行する場合
# docker compose run --rm font ./run_ff_ttx.sh -F [オプション]
#
# コンテナに入ってから実行する場合
# docker compose run -it --rm font
# exit で抜けます
#
# ソースコードに変更があった場合、先に
# docker compose build
# を実行

FROM ubuntu:24.04

RUN apt update && \
  DEBIAN_FRONTEND=noninteractive apt install -y \
  bc \
  fontforge \
  python3-venv \
  locales \
  micro \
  && \
  locale-gen ja_JP.UTF-8

RUN python3 -m venv /opt/venv && \
  /opt/venv/bin/pip install --no-cache-dir fonttools skia-pathops

ENV PATH="/opt/venv/bin:$PATH"
ENV VIRTUAL_ENV="/opt/venv"

ENV LANG=ja_JP.UTF-8
ENV LANGUAGE=ja_JP:ja
ENV LC_ALL=ja_JP.UTF-8

WORKDIR /app
COPY . /app

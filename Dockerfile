# syntax=docker.io/docker/dockerfile:1.4
FROM --platform=linux/riscv64 cartesi/python:3.10-slim-jammy

WORKDIR /opt/cartesi/dapp

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  build-essential wget xxd \
  && rm -rf /var/apt/lists/*


ARG FILE_NAME=stories15M.bin
ARG FILE_URL=https://huggingface.co/karpathy/tinyllamas/resolve/main/stories15M.bin


# RUN wget https://huggingface.co/karpathy/tinyllamas/resolve/main/stories15M.bin
# COPY ./stories15M.bin .
# Try to copy the file. If it doesn't exist, download it using wget.
# RUN if ! cp $FILE_NAME /$FILE_NAME 2>/dev/null; then wget -O /$FILE_NAME $FILE_URL; fi
COPY ./tokenizer.bin .
COPY ./stories15M.bin .
COPY ./run.c .
RUN gcc -Ofast run.c  -lm  -o run

COPY ./requirements.txt .
RUN pip install -r requirements.txt --no-cache \
  && find /usr/local/lib -type d -name __pycache__ -exec rm -r {} +

COPY ./entrypoint.sh .
COPY ./trust-and-teach.py .

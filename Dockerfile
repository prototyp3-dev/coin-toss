# syntax=docker.io/docker/dockerfile:1.4
FROM --platform=linux/riscv64 cartesi/python:3.10-slim-jammy

WORKDIR /opt/cartesi/dapp

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  build-essential xxd \
  && rm -rf /var/apt/lists/*


# Use an appropriate base image, for example, Python
FROM python:3.8

# Install necessary libraries
RUN pip install transformers huggingface_hub

# $ ./run stories260K/stories260K.bin -z stories260K/tok512.bin -t 0.0

# COPY ./tokenizer.bin .
# wget https://huggingface.co/karpathy/tinyllamas/resolve/main/stories15M.bin
# COPY ./stories15M.bin .
# COPY ./run.c .

# RUN gcc -Ofast run.c  -lm  -o run

COPY ./requirements.txt .
RUN pip install -r requirements.txt --no-cache \
  && find /usr/local/lib -type d -name __pycache__ -exec rm -r {} +

COPY ./entrypoint.sh .
COPY ./trust-and-teach.py .

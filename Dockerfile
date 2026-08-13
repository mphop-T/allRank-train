# changed the file to make it work with the dependencies since project has older versions
FROM python:3.9-slim

LABEL maintainer="MLR <allrank@allegro.pl>"

WORKDIR /allrank

RUN apt-get update && apt-get install -y gcc g++ && rm -rf /var/lib/apt/lists/*

COPY requirements.txt setup.py Makefile README.md ./

# Use pip to install everything, skip setup.py
RUN pip install --upgrade pip

# Install all dependencies including your package as editable
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install torch==1.13.1 torchvision==0.14.1 --extra-index-url https://download.pytorch.org/whl/cpu
RUN pip install -e .  # This replaces python setup.py install
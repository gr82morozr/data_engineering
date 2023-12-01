#Deriving the latest base image
FROM python:latest

COPY requirements.txt ./

RUN  pip install --no-cache-dir --upgrade pip \
  && pip install --no-cache-dir -r requirements.txt

# Copy your scripts to the container
COPY . /app

# Set the working directory
WORKDIR /app


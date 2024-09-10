FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update and install common packages (same as base)
RUN apt-get update && apt-get install -y \
  python3.10 \
  python3-pip \
  curl \
  wget \
  git \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install common Python packages (same as base)
RUN pip3 install --no-cache-dir --upgrade pip && \
  pip3 install --no-cache-dir \
  numpy \
  pandas \
  scikit-learn \
  matplotlib

# Install additional packages
RUN apt-get update && apt-get install -y \
  nodejs \
  npm \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install TensorFlow and Keras
RUN pip3 install --no-cache-dir tensorflow keras

# Install PyTorch
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Install some Node.js packages globally
RUN npm install -g \
  express \
  lodash \
  moment

# Create large files to simulate longer build time
RUN dd if=/dev/urandom of=/large_file_1 bs=1M count=500 && \
  dd if=/dev/urandom of=/large_file_2 bs=1M count=500 && \
  rm /large_file_1 /large_file_2

# Set working directory
WORKDIR /app

# Create a simple Python script that uses one of the new packages
RUN echo 'import tensorflow as tf; print(f"TensorFlow version: {tf.__version__}")' > tf_version.py

CMD ["python3", "tf_version.py"]
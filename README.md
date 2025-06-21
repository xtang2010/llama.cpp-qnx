# llama.cpp port to QNX

This is to port GGML's [llama.cpp](https://github.com/ggml-org/llama.cpp) <img src="https://avatars.githubusercontent.com/u/134263123?s=48&v=4" width=24 /> project to QNX. Currently only support CPU based ggml. Note llama.cpp is in active development, code is change fast. I have verify the port on llama.cpp tag "b5712", and QNX SDP 8.0

## How to build

You can build by yourself, or you can direct download the [latest binaries](https://github.com/xtang2010/llama.cpp-qnx/releases/download/b2025062101/llama-b2025062101-bin-qnx8-cpu-x64.tgz).

**NOTE**: QNX ports are only supported from a Linux host operating system

Use `$(nproc)` instead of `4` after `JLEVEL=` and `-j` if you want to use the maximum number of cores to build this project.
32GB of RAM is recommended for using `JLEVEL=$(nproc)` or `-j$(nproc)`.

### Compile the port for QNX in a Docker container

**Pre-requisite**: Install Docker on Ubuntu https://docs.docker.com/engine/install/ubuntu/
```bash
# Create a workspace
mkdir -p ~/qnx_workspace && cd ~/qnx_workspace
git clone https://github.com/qnx-ports/build-files.git

# Build the Docker image and create a container
cd build-files/docker
./docker-build-qnx-image.sh
./docker-create-container.sh

# Now you are in the Docker container

# Source your SDP
source ~/qnx800/qnxsdp-env.sh

# Clone llama.cpp
cd ~/qnx_workspace
git clone https://github.com/xtang2010/llama.cpp-qnx.git build-files/ports/llama.cpp
git clone https://github.com/ggml-org/llama.cpp.git

# Build llama.cpp
QNX_PROJECT_ROOT="$(pwd)/llama.cpp" make -C build-files/ports/llama.cpp -j4
```

### Compile the port for QNX on Ubuntu host
```bash
# Clone the repos
mkdir -p ~/qnx_workspace && cd ~/qnx_workspace
git clone https://github.com/qnx-ports/build-files.git
git clone https://github.com/xtang2010/llama.cpp-qnx.git build-files/ports/llama.cpp
git clone https://github.com/ggml-org/llama.cpp.git

# Source your SDP
source ~/qnx800/qnxsdp-env.sh

# Build llama.cpp
QNX_PROJECT_ROOT="$(pwd)/llama.cpp" make -C build-files/ports/llama.cpp -j4
```

## How to run

scp libraries and tests to the target.
```bash
TARGET_HOST=<target-ip-address-or-hostname>

# Move llama.cpp test binaries and libs to your x86_64 QNX target
scp -r build-files/ports/llama.cpp/nto-x86-64/build/bin qnxuser@$TARGET_HOST:/data/home/qnxuser/llama.cpp/
```
You will also need gguf model file for llama.cpp to perform. You can download your faviroute [Hugging Face](https://huggingface.co/), or I have prepared a couple of sample for you. Download [here]([https://github.com/xtang2010/release/models.tgz](https://github.com/xtang2010/llama.cpp-qnx/releases/download/b2025062101/models.tgz))

Download these models on target.
```base
# Download models and copy it to target
cd build-files/ports/llama.cpp
curl -L https://github.com/xtang2010/llama.cpp-qnx/releases/download/b2025062101/models.tgz -O - | tar xzvf -
scp -r models qnxuser@$TARGET_HOST:/data/home/qnxuser/llama.cpp/
```

Run llama-cli on the target, you can start a chat on console.
```bash
# ssh on target
ssh qnxuser@$TARGET_HOST
cd /data/home/qnxuser/llama.cpp/
export LD_LIBRARY_PATH=`pwd`/bin:$LD_LIBRARY_PATH
bin/llama-cli -m models/qwen3-751.63M-Q4_K_M.gguf 
```
Run llama-server on the target, and chat with your faviourte web browser on Linux Host.
```bash
# ssh on target
ssh qnxuser@$TARGET_HOST
cd /data/home/qnxuser/llama.cpp/
export LD_LIBRARY_PATH=`pwd`/bin:$LD_LIBRARY_PATH
bin/llama-server -m models/qwen3-751.63M-Q4_K_M.gguf --host 0.0.0.0 
```
And now start a browser on your Linux host, point it to :

http://\<target-ip-address-or-hostname\>:8080/


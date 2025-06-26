# llama.cpp port to QNX

This is to port GGML's [llama.cpp](https://github.com/ggml-org/llama.cpp) <img src="https://avatars.githubusercontent.com/u/134263123?s=48&v=4" width=24 /> project to QNX. Currently only support CPU based ggml. With llama.cpp, you can run all the latest LLM models on your own hardware (including Gemma3, Llama3, Deepseek-r1, Qiwen3, ...)

## Use pre-built binary

If you don't want to build by yourself, you can choose to use the [pre-built binary](https://github.com/xtang2010/llama.cpp-qnx/releases). 

## How to build

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

## How to run test

llama.cpp come with test code to help you test your new binaries. If you wish to execute these test cases, you must do this.
```bash
# Build test script
QNX_PROJECT_ROOT="$(pwd)/llama.cpp" make -C build-files/ports/llama.cpp -j4 test

# Move all the binaries, supporting files to your QNX target
TARGET_HOST=<target-ip-address-or-hostname>

scp -r build-files/ports/llama.cpp/nto-x86-64/build/bin qnxuser@$TARGET_HOST:/data/home/qnxuser/llama.cpp/
scp build-files/ports/llama.cpp/nto-x86-64/build/llama-test.sh qnxuser@$TARGET_HOST:/data/home/qnxuser/llama.cpp/
scp -r llama.cpp/models qnxuser@$TARGET_HOST:/data/home/qnxuser/llama.cpp/
```
You can now move to the target to execute the test cases
```bash
ssh qnxuser@$TARGET_HOST
cd /data/home/qnxuser/llama.cpp/
export LD_LIBRARY_PATH=`pwd`/bin:$LD_LIBRARY_PATH
./llama-test.sh
```
You get the result on terminal, and all detail test run output will be in llama-test.log

## How to run llama.cpp

scp libraries and tests to the target, if you haven't do so
```bash
TARGET_HOST=<target-ip-address-or-hostname>

# Move llama.cpp test binaries and libs to your x86_64 QNX target
scp -r build-files/ports/llama.cpp/nto-x86-64/build/bin qnxuser@$TARGET_HOST:/data/home/qnxuser/llama.cpp/
```
You will also need gguf model file for llama.cpp to perform. You can download your faviroute from [Hugging Face](https://huggingface.co/); another way is download models from [ollama](https://ollama.com/library), and use [OllamaToGGUF](https://github.com/xtang2010/OllamaToGGUF) to convert them to gguf. Or I have just prepared a [sample]([https://github.com/xtang2010/release/models.tgz](https://github.com/xtang2010/llama.cpp-qnx/releases/download/b2025062101/models.tgz)) for you.

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


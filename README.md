# llama.cpp port to QNX

**NOTE**: QNX ports are only supported from a Linux host operating system

Use `$(nproc)` instead of `4` after `JLEVEL=` and `-j` if you want to use the maximum number of cores to build this project.
32GB of RAM is recommended for using `JLEVEL=$(nproc)` or `-j$(nproc)`.

# Compile the port for QNX in a Docker container

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
git clone https://github.com/ggml-org/llama.cpp.git

# Build llama.cpp
QNX_PROJECT_ROOT="$(pwd)/llama.cpp" make -C build-files/ports/llama.cpp install -j4
```

# Compile the port for QNX on Ubuntu host
```bash
# Clone the repos
mkdir -p ~/qnx_workspace 
cd ~/qnx_workspace && git clone https://github.com/qnx-ports/build-files.git
cd build-files/ports && git clone https://github.com/xtang2010/llama.cpp.git
cd ~/qnx-workspace && git clone https://github.com/ggml-org/llama.cpp.git

# Source your SDP
source ~/qnx800/qnxsdp-env.sh

# Build llama.cpp
QNX_PROJECT_ROOT="$(pwd)/llama.cpp" make -C build-files/ports/llama.cpp -j4
```

# How to run

scp libraries and tests to the target (note, mDNS is configured from
/boot/qnx_config.txt and uses qnxpi.local by default).
```bash
TARGET_HOST=<target-ip-address-or-hostname>

# Move llama.cpp test binaries and libs to your QNX target (assume x86_64)
scp -r build-files/ports/llama.cpp/nto-x86-64/build/bin qnxuser@$TARGET_HOST:/data/home/qnxuser/llama.cpp

```
Run  on the target.
```bash
# on target
cd /data/home/qnxuser/llama.cpp
export LD_LIBRARY_PATH=`pwd`:$LD_LIBRARY_PATH
llama-cli -m <module>



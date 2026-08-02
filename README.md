# Blackcoin More Docker Images

This repository provides Docker configurations for running **Blackcoin More**—an advanced, energy-efficient Proof-of-Stake (PoS) cryptocurrency client.

It features multi-architecture support (`linux/amd64` and `linux/arm64`) and offers two main variants tailored for different needs: **Minimal** (scratch-based) and **Debian/Full** (debian-slim-based).

---

## 📦 Image Variants

### 1. ⚡ The Minimal Image (`blackcoin-more-minimal`)
The minimal image is built **`FROM scratch`** to ensure a minimal attack surface and an ultra-lightweight footprint (under 30MB). It is designed specifically for secure, production-grade staking nodes and RPC servers.
* **Zero Overhead**: No package manager, no system shell (`/bin/sh` or `/bin/bash`), and no unnecessary system utilities.
* **Stripped Binaries**: Contains only the compiler-stripped Blackcoin More binaries and their direct dynamic link dependencies.
* **High Security**: Since it lacks a shell, it has a near-zero attack surface, preventing exploit payload executions inside the container.
* **Pre-bundled Utilities**: Includes `bc` and `jq` to facilitate basic scripting needs.

### 2. 🐧 The Full/Debian Image (`blackcoin-more-debian`)
The full image is built **`FROM debian:bookworm-slim`** to provide a familiar environment for developers and administrators. 
* **Shell Support**: Contains a standard shell (`bash` / `sh`), making it easy to attach, inspect, and debug.
* **Standard Environment**: Binaries are added directly to the system `PATH`, allowing you to run commands without specifying absolute paths.
* **Easy Orchestration**: Perfect for users who need to run companion cron jobs, custom diagnostic checks, or who prefer interactive terminal access.

> [!NOTE]
> **Multi-Architecture Manifests:** The official images published to Docker Hub use unified multi-arch tags (e.g., `blackcoin-more-minimal-v28x:28.x`) that dynamically support both `linux/amd64` (x86_64) and `linux/arm64`. Docker automatically pulls the architecture matching your system. If you compile locally using the `build.sh` script, it builds for your specific CPU type and generates a tagged image with the architecture suffix (e.g. `-x86_64`).

---

## ⚙️ Ports Reference

Both images expose the same network ports:

| Port | Protocol | Network | Description |
|---|---|---|---|
| **15714** | TCP | Mainnet | Peer-to-Peer (P2P) network communications |
| **15715** | TCP | Mainnet | RPC Server interface |
| **25714** | TCP | Testnet | Peer-to-Peer (P2P) network communications |
| **25715** | TCP | Testnet | RPC Server interface |

---

## 🚀 How to Run the Images

Both images can be run either as **root** (quick start) or as a **non-root user** (highly recommended for production security).

### Option A: Running the Minimal Image (`scratch`-based)

#### 1. Secure Execution as a Non-Root User (Recommended)
Running as a non-root user (e.g. using `docker run` flags) is a security best practice:
* **User and Group IDs:** Passing `--user $(id -u):$(id -g)` dynamically sets the UID and GID to match the active host user, preventing file ownership/permission conflicts on the mounted volume. Note that the actual values depend on your host OS (e.g. typically `1000:1000` on single-user Linux or `501:20` on macOS).
* **Directory Resolution:** Since the scratch image lacks dynamic user databases (`/etc/passwd`), the runtime home directory defaults to `/`. Thus, the default data directory (`~/.blackmore`) resolves to `/.blackmore` inside the container. 
* **Local Loopback Binding:** Binding ports to `127.0.0.1` ensures that the RPC interface (`15715`) and P2P synchronization ports are only accessible locally or via SSH tunneling, preventing exposure to the public internet.

```bash
docker run -itd \
  --name blackcoindocker \
  --user $(id -u):$(id -g) \
  -p 127.0.0.1:15714:15714 \
  -p 127.0.0.1:15715:15715 \
  -v ~/.blackmoreDocker:/.blackmore \
  blackcoinorg/blackcoin-more-minimal-v28x:28.x \
  blackmored
```

#### 2. Running as Root (Quick Start)
When running as root, the default data directory in the container resolves to `/root/.blackmore`:

```bash
docker run -d \
  --name blackcoin-node \
  -p 15714:15714 \
  -p 15715:15715 \
  -v /path/to/local/data:/root/.blackmore \
  blackcoinorg/blackcoin-more-minimal-v28x:28.x \
  blackmored
```

---

### Option B: Running the Full Image (`debian`-based)

#### 1. Secure Execution as a Non-Root User (Recommended)
```bash
docker run -itd \
  --name blackcoin-node-full \
  --user $(id -u):$(id -g) \
  -p 127.0.0.1:15714:15714 \
  -p 127.0.0.1:15715:15715 \
  -v ~/.blackmoreDocker:/.blackmore \
  blackcoinorg/blackcoin-more-debian-v28x:28.x \
  blackmored
```

#### 2. Running as Root (Quick Start)
```bash
docker run -d \
  --name blackcoin-node-full \
  -p 15714:15714 \
  -p 15715:15715 \
  -v /path/to/local/data:/root/.blackmore \
  blackcoinorg/blackcoin-more-debian-v28x:28.x \
  blackmored
```

---

### Option C: Running the Beta/Development Images (`blackcoindev`)

If you want to test the latest development builds (e.g., those generated via `gh-build-28-bdev.sh`), use the `blackcoindev` namespace images.

#### Minimal Development Image
```bash
docker run -itd \
  --name blackcoindocker-dev \
  --user $(id -u):$(id -g) \
  -p 127.0.0.1:15714:15714 \
  -p 127.0.0.1:15715:15715 \
  -v ~/.blackmoreDocker:/.blackmore \
  blackcoindev/blackcoin-more-28.4.0-minimal:v28-SEGWIT \
  blackmored
```

#### Full/Debian Development Image
```bash
docker run -itd \
  --name blackcoin-node-full-dev \
  --user $(id -u):$(id -g) \
  -p 127.0.0.1:15714:15714 \
  -p 127.0.0.1:15715:15715 \
  -v ~/.blackmoreDocker:/.blackmore \
  blackcoindev/blackcoin-more-28.4.0-debian:v28-SEGWIT \
  blackmored
```

---

## 💻 Interacting with the Node

You can execute commands on the running node using the command-line interface (`blackmore-cli`). Use the appropriate container name (`blackcoindocker` or `blackcoin-node-full`).

### Interacting with the Minimal Image
Since there is no shell, invoke the absolute path to `blackmore-cli` directly via `docker exec`:

```bash
# Get blockchain info
docker exec blackcoindocker /usr/local/bin/blackmore-cli getblockchaininfo

# Check wallet info
docker exec blackcoindocker /usr/local/bin/blackmore-cli getwalletinfo

# Safely stop daemon
docker exec blackcoindocker /usr/local/bin/blackmore-cli stop
```

### Interacting with the Full Image
For the full image, you can use the command directly without path prefixing:

```bash
# Get blockchain info directly
docker exec blackcoin-node-full blackmore-cli getblockchaininfo

# Alternatively, open an interactive bash shell in the container
docker exec -it blackcoin-node-full bash

# (Inside container shell)
blackmore-cli getwalletinfo
blackmore-cli getstakinginfo
exit
```

---

## 🐳 Docker Compose Example

For ease of deployment, you can use **Docker Compose**. Create a `docker-compose.yml` file configuring the secure, non-root environment:

```yaml
version: '3.8'

services:
  # Staking Node Config
  blackmored:
    image: blackcoinorg/blackcoin-more-minimal-v28x:28.x   # Or use blackcoinorg/blackcoin-more-debian-v28x:28.x
    container_name: blackcoindocker
    user: "${UID:-1000}:${GID:-1000}"   # Dynamically maps host UID/GID (defaults to 1000:1000)
    restart: unless-stopped
    ports:
      - "127.0.0.1:15714:15714"
      - "127.0.0.1:15715:15715"
    volumes:
      - ~/.blackmoreDocker:/.blackmore
    # Command is resolved within the default PATH of the image
    command: ["blackmored", "-printtoconsole"]
```

Start the service with:
```bash
docker compose up -d
```


---

## 🛠️ Building the Images Locally

Configure and build these images locally with the provided scripts:

### Local single-architecture build:
```bash
./build.sh
```
This interactive script guides you through setting your timezone, branch, and DockerHub registry options.

### Multi-architecture build (buildx):
To build multi-arch versions (`linux/amd64` and `linux/arm64`) and push them to your registry:
```bash
./gh-build-28.sh
```
This uses Docker Buildx to cross-compile and publish both architectures simultaneously.

---

## 🤖 GitHub Actions CI/CD Workflow

For high-performance automated builds, the repository includes a GitHub Actions workflow ([docker_build_push_28.yml](file:///Users/blackcoindev/gitkraken/docker-blk/docker_build_push_28.yml)):
* **Native Parallel Builders**: Rather than using QEMU emulation (which can take over 2 hours), the workflow builds `linux/amd64` natively on `ubuntu-22.04` and `linux/arm64` natively on `ubuntu-22.04-arm`. This reduces build times to under 10 minutes.
* **Conditional Optimization**: The base image build ([Dockerfile.minbase](file:///Users/blackcoindev/gitkraken/docker-blk/Dockerfile.minbase)) automatically detects the compilation target and only passes `--enable-sse2` when building for `amd64`, preventing build failures on ARM64.
* **Clean Multi-Registry Pipeline**: To keep the public Docker Hub registry clean and free of intermediate tags (like `28.x-amd64` or `28.x-arm64`), the workflow pushes the architecture-specific images to **GitHub Container Registry (GHCR)**. The final assembly step then uses `docker buildx imagetools create` to pull from GHCR and publish the final unified manifest list directly to **Docker Hub** under the single `28.x` tag.


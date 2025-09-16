# Bluefin OS: A Developer's Guide & Bulletproof Setup

**Core Focus:** Bluefin OS, Dev Env Setup using (FlatPak/HomeBrew+ToolBox+ Podman/Docker + Jetbrain IDE)
**Explore More Idea:** DevContainer, DevPod

---

## 1. Welcome & My "Why"

Hi there! I recently switched to Bluefin OS after a stint with Fedora Silverblue. While I loved the immutable OS concept, I craved a version that was custom-built for developers. Bluefin is exactly that: it's Fedora Silverblue supercharged with all the tools and commands (`ujust`) that make a developer's life easier, right out of the box.

My journey wasn't just about switching; it was about solving a core fear: "What if it breaks?" I invested a whole week in designing a disaster recovery plan so I could use Bluefin fearlessly. This guide is everything I wish I'd had when I started. It covers the "how," the "why," and the "what if it all goes wrong."

## 2. Core Concept: The Immutable OS

Bluefin OS is an immutable Linux distribution built on a **Universal Blue** image. Its core principle is that the host operating system's root filesystem is **read-only**.

*   **Why?** **Stability & Security:** This design prevents accidental or malicious system changes, ensures a consistent state, and simplifies atomic, image-based updates and rollbacks. Think of it as separating the **OS Layer (the immutable "engine")** from the **User Layer (your mutable "world" in `/home`)**.
*   **The Challenge:** You can't (and shouldn't) use `sudo dnf install` on the host, as it "pollutes" the immutable base.
*   **The Solution: Containerization & Sandboxing.** All your software, dev tools, and services run in isolated, mutable containers or sandboxes, leaving the host OS pristine.
*   **First Step: Enable Developer Mode.** This is essential for the workflows below.
    ```bash
    ujust devmode    # Enables Developer Mode
    ujust dx-group   # Adds your user to the 'dev' group (log out and back in after)
    ```

### Key Host OS Management Commands:
- **`rpm-ostree status`**: View the current OS deployment and any available rollbacks.
- you can **“save” the preferred version of Silverblue OS** that you are most satisfied with, and then later you can pick it from the boot menu. You do this with a simple command sudo ostree admin pin #, where # is the order of the OS images available when you type rpm-ostree status.
- **`rpm-ostree rollback`**: Revert to the previous OS version (lifesaver!).
- **`ujust update`**: The easy button. Updates the system, Flatpaks, and Toolbox packages.
- **`ujust clean-system`**: Cleans up containers, Flatpak runtimes, and temp files. Run this regularly.
- **`rpm-ostree cleanup -m`**: Removes old OS deployment images to free up disk space.


## 3. Development Environment: The "Right Place for Everything"

The golden rule of an immutable OS is knowing *where* to install things. Here’s the strategy that works perfectly.

### 3.1 Your Dev Workshop: Toolbox for CLI Tools
*   **Concept:** Your primary development shell. A mutable Fedora container that feels seamless but is isolated from the host. It survives OS rollbacks.
*   **Tool:** `toolbox`

**SOP: Create Your Development Toolbox**
**Script:** `dev-env_toolbox.sh`
**Prerequisite:** Ensure Developer Mode is enabled.
```bash
#!/bin/bash
# Create the container
toolbox create --container dev-shell
# Enter the container to run subsequent commands
toolbox enter dev-shell

# --- INSIDE TOOLBOX CONTAINER ---
# Update and install core packages
sudo dnf update -y
sudo dnf install -y java-21-openjdk-devel maven git python3 python3-pip podman docker-compose kubectl helm awscli azure-cli httpie curl wget unzip jq

# Install Google Cloud CLI via official repo
sudo tee /etc/yum.repos.d/google-cloud-sdk.repo << 'EOR'
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=0
EOR
sudo dnf install -y google-cloud-cli

# Install SDKMAN for Java/Gradle management
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java 17.0.12-tem
sdk install java 21.0.4-tem
sdk install gradle 8.10.2
```
**To run it:** `bash dev-env_toolbox.sh`
**Note:** If `dev-shell` already exists, remove it first: `toolbox rm dev-shell`

**Pro Tip:** Connect IntelliJ (installed via Flatpak) to this toolbox via SSH. Your IDE will use the JDK, Maven, and other tools from inside the container, keeping the host clean.

### 3.2 Host Machine Tools: Homebrew (Use Sparingly)
*   **Concept:** An alternative package manager for installing a few command-line tools directly onto the host.
*   **Use Case:** For tools that don't need full isolation and aren't available elsewhere.
*   **Configuration:** Apps store configs in `~/.config/` or as dotfiles (`~/.myapprc`). These are in your `/home` dir and are automatically backed up.
```bash
brew install <formula> # Example installation
```

### 3.3 GUI Apps: Flatpak is King
*   **Concept:** Sandboxed desktop applications. This is the preferred way to install IDEs and GUI tools.
*   **Tool:** `flatpak`
*   **Configuration:** All app data and configs are stored in `~/.var/app/`. Since this is in your `/home` directory, it's all automatically backed up.

**SOP: Install Essential GUI Apps**
**Script:** `gui-apps_flatpak.sh`
```bash
#!/bin/bash
# Install from Flathub repository
flatpak install -y flathub com.visualstudio.code
flatpak install -y flathub com.jetbrains.IntelliJ-IDEA-Community
flatpak install -y flathub com.github.muriloventuroso.diffuse
flatpak install -y flathub io.dbeaver.DBeaverCommunity
flatpak install -y flathub com.getpostman.Postman

# System Maintenance
flatpak uninstall --unused -y
flatpak update -y
```
**To run it:** `bash gui-apps_flatpak.sh`

### 3.4 Infrastructure Services: Podman on the Host
*   **Concept:** Run background services (databases, message brokers, monitoring) as containers **directly on the host**, not inside your Toolbox. This is a crucial separation: your Toolbox is for *building* software, the host's Podman is for *running* services.
*   **Tools:** `podman`, `docker-compose` (via `podman-docker`).
*   **Orchestration:** Use **Docker Compose Profiles** to manage groups of services.

**SOP: Deploy Local Infrastructure**
**Script:** `infra-containers.sh`
```bash
#!/bin/bash
# Create directory structure for compose files and data
mkdir -p ~/infra/{logs,dashboards,compose}
cd ~/infra/compose

# Create your docker-compose.yml file here defining profiles:
# profile "core": postgres, redis, kafka
# profile "observability": prometheus, grafana
# profile "logging": elasticsearch, kibana
# profile "security": keycloak, vault

# Start specific service groups
docker compose --profile core up -d
docker compose --profile observability up -d
docker compose --profile security up -d

# Verify
docker ps
docker compose logs -f
```
**To run it:**
1.  Create your `docker-compose.yml` file in `~/infra/compose/`.
2.  Run `bash infra-containers.sh`.

## 4. The "Oh No!" Plan: Disaster Recovery (DR)

This is the system that gives me the confidence to experiment. It creates a "true replica" backup.

### 4.1 How It Works: The Daily Automated Backup
A `systemd` timer runs a master script (`master-backup.sh`) every day. This script:
1.  **Backs up the Host OS:** Saves a list of your layered packages and all your GNOME/desktop settings.
2.  **Backs up App & Container State:**
    *   **The Magic Trick:** Uses `podman commit` to take a snapshot of every running container (including your Toolbox!). This safely captures the state of all your installed tools.
    *   Saves lists of all your Flatpaks, Homebrew packages, and Podman images.
3.  **The Anchor:** You use **Deja Dup** (or your preferred tool) to back up your entire `/home` directory to an external drive/cloud. This one step saves all your personal files *and* all the data from the scripts above.

### 4.2 How To Restore Everything
**Scenario:** Your laptop dies. You have a new machine with a fresh Bluefin install.
1.  **Restore /home:** Use Deja Dup to restore your entire `/home` directory.
2.  **Restore the Host:** Run `restore-host-configs.sh`. This reinstalls your layered packages and brings back your desktop look and feel. **Reboot.**
3.  **Restore Your World:** Run `restore-system-state.sh`. This script:
    *   Reinstalls all your GUI apps (Flatpak).
    *   Reinstalls your host CLI tools (Homebrew).
    *   Rebuilds every container (Toolbox, Distrobox, services) from its last snapshot.

## 5. Quick Command Reference

```bash
# HOST OS
ujust update                 # Update everything
rpm-ostree status           # Check OS deployments
rpm-ostree rollback         # Roll back OS

# TOOLBOX
toolbox enter dev-shell     # Enter your dev container
toolbox list                # List containers
toolbox rm dev-shell        # Delete a container

# FLATPAK
flatpak install flathub <app>  # Install an app
flatpak list --app          # List installed apps

# PODMAN & DOCKER
podman ps                   # List running containers
docker compose up -d        # Start services

# DISASTER RECOVERY
bash ~/bin/master-backup.sh      # Manually run the backup
# After a disaster, restore /home first, then run:
bash ~/bin/restore-host-configs.sh
bash ~/bin/restore-system-state.sh
```

## 6. Conclusion

Bluefin OS offers a powerful and modern development experience by combining the rock-solid stability of an immutable OS with the flexibility of containers. By following this layered approach—using Toolbox for tools, Flatpak for apps, and Podman for services—you get the best of both worlds. And with a solid disaster recovery plan in place, you can explore and experiment with complete confidence.

Welcome to Bluefin! I hope this guide makes your journey as rewarding as mine has been.

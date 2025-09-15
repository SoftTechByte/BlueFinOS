
## 🧩 SOP: Installing and Exporting Software via Distrobox

### 📁 Objective

Install any Linux-compatible software inside a containerized environment using Distrobox, and optionally export it to the host system for seamless access.

---

### 🔧 Prerequisites

- BlueFin OS with `distrobox`, `podman` or `docker` installed
- Internet access for package downloads
- Base image (e.g., `fedora:latest`, `ubuntu:22.04`) compatible with target software

---

### 🧱 Step 1: Create the Distrobox Container

```bash
distrobox create --name software-hub --image fedora:latest
```

- `--name`: Logical identifier for the container
- `--image`: Base OS image (choose glibc-based for GUI apps)

> Optional: Add `--home` or `--volume` flags to mount host directories

---

### 🚪 Step 2: Enter the Container

```bash
distrobox enter software-hub
```

This opens a shell inside the container, isolated from the host.

---

### 📦 Step 3: Install the Desired Software

Use the native package manager of the container OS:

```bash
# Fedora example
sudo dnf install bcompare
```

Or download and install manually:

```bash
sudo dnf install https://www.scootersoftware.com/bcompare-4.4.7.26154.x86_64.rpm
```

Repeat for other tools as needed.

---

### 🚀 Step 4: Export the App to Host (Optional)

```bash
distrobox-export --app bcompare
```

This creates a `.desktop` launcher and exposes the app to your host system.

> You can now launch the app from your BlueFin OS menu or CLI as if it were native.

---

### 🧼 Step 5: Exit and Maintain

```bash
exit
```

To list containers:

```bash
distrobox list
```

To remove:

```bash
distrobox rm software-hub
```

---


---

## 🧠 Notes

- Installed software does **not consume RAM or CPU** until launched
- Containers are **user-space overlays**, not full VMs
- You can snapshot containers using Podman/Docker volumes or export configs

---

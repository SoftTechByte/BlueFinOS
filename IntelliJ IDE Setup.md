
### **SOP: Spring Boot Development via IntelliJ & Toolbox (SSH)**

**Objective:** To run the IntelliJ IDE UI on the host machine while executing all development tools (JDK, Maven) and processes inside an isolated Toolbox container, connected via SSH.

---

### **Phase 1: Toolbox Container Setup & SSH Configuration**

**Goal:** Configure the Toolbox container as a remote SSH server.

1.  **Enter the Toolbox Container:**
    ```bash
    toolbox enter devbox
    ```

2.  **Install and Configure the SSH Server:**
    ```bash
    # 1. Install the SSH server
    sudo dnf install openssh-server -y
    
    # 2. Generate host keys
    sudo ssh-keygen -A
    
    # 3. Start the SSH server on port 2222 in the background
    sudo /usr/sbin/sshd -p 2222 -D &
    ```

3.  **Set a Password for User Authentication:**
    ```bash
    # Set a password for the current user (required for SSH password login)
    passwd
    ```
    **Note:** For a more secure setup, configure SSH key-based authentication later.

4.  **(Optional) Test the SSH Connection from the Host Machine:**
    ```bash
    # Test from your host OS terminal, not inside Toolbox.
    ssh -p 2222 <your_username>@localhost
    # Example: ssh -p 2222 mayank@localhost
    ```
    *If successful, you will get a new shell inside your Toolbox container.*

---

### **Phase 2: Connect IntelliJ IDE via Gateway**

**Goal:** Link the IntelliJ IDE on your host to the Toolbox development environment.

1.  **On the Host Machine:**
    *   Open **JetBrains Gateway**.
    *   Select **SSH** as the connection method.
    *   Click **New Connection**.

2.  **Configure SSH Connection:**
    *   **Host:** `localhost`
    *   **Port:** `2222`
    *   **User Name:** `<your_username>` (e.g., `mayank`)
    *   **Auth type:** Password (use the password you set in Phase 1, Step 3).
    *   Click **Check Connection and Continue**.

3.  **Download IDE Backend:**
    *   Gateway will test the connection and prompt you to download and install the required IDE backend (e.g., IntelliJ) into the Toolbox container.
    *   Select your preferred IDE version and proceed.

4.  **Launch and Open Project:**
    *   Once the download is complete, the full IntelliJ IDE window will open on your host.
    *   To open a project, navigate to your workspace directory inside the Toolbox container (e.g., `/var/home/mayank/Projects/`).

---

### **Phase 3: JDK & Toolchain Configuration**

**Goal:** Ensure consistent JDK visibility between the Toolbox shell and IntelliJ.

#### **Part A: Setup Inside Toolbox Container**

1.  **Verify or Install Tools (In Toolbox Terminal):**
    ```bash
    java -version
    mvn -v
    ```
    *If not installed, use SDKMAN inside the container:*
    ```bash
    # Install SDKMAN, then a JDK and Maven
    sdk install java 21.0.4-tem
    sdk install maven
    ```

2.  **Set `JAVA_HOME` and `PATH` Environment Variables:**
    ```bash
    # Add these lines to your ~/.bashrc file
    echo 'export JAVA_HOME=$HOME/.sdkman/candidates/java/current' >> ~/.bashrc
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc

    # Reload the configuration
    source ~/.bashrc
    ```

3.  **Purge IntelliJ's JDK Cache (Critical Step):**
    ```bash
    # This forces IntelliJ to rediscover the correct JDK
    rm -rf ~/.jdks
    ```

#### **Part B: Setup Inside IntelliJ IDE**

4.  **Configure Project SDK:**
    *   In the IntelliJ IDE (connected via Gateway), go to **File → Project Structure → Project SDK**.
    *   **Remove all existing incorrect JDK entries** from the list.
    *   Click **Add SDK (+ sign) → JDK**.
    *   Navigate to the JDK path shown by `echo $JAVA_HOME` in your Toolbox (e.g., `/home/mayank/.sdkman/candidates/java/current`).
    *   Click **OK**. Set this new SDK as the **Project SDK**.

5.  **Configure Maven Runner:**
    *   Go to **Settings → Build, Execution, Deployment → Build Tools → Maven → Runner**.
    *   Under **JRE**, select the same SDK you just added (e.g., `21.0.4-tem`).
    *   Click **OK** to save.

---

### **Phase 4: Project Execution**

**Goal:** Create and run a Spring Boot application.

1.  **Create a New Project:**
    *   Generate a Spring Boot project from [https://start.spring.io/](https://start.spring.io/).
    *   Extract the project ZIP file into your workspace directory **inside the Toolbox container**.

2.  **Open the project** in IntelliJ via **File → Open**.

3.  **Run the Application:**
    *   **Method A (IntelliJ UI):** Find the `@SpringBootApplication` class and click the run button next to it (recommended).
    *   **Method B (Terminal):** Open the terminal in IntelliJ (which is inside Toolbox) and run:
        ```bash
        ./mvnw spring-boot:run
        ```

4.  **Access the Application:**
    *   The app runs inside the Toolbox container but is network-shared with the host.
    *   Open your host machine's browser and go to: [http://localhost:8080](http://localhost:8080)

---

### **✅ Architecture & Summary**

| Component               | Location          | Responsibility                                  |
| ----------------------- | ----------------- | ----------------------------------------------- |
| **IntelliJ IDE (UI)**   | Host OS           | Provides the user interface and editor.         |
| **Development Tools**   | Toolbox Container | JDK, Maven, project files, running application. |
| **Connection**          | SSH (Port 2222)   | Links the Host UI to the Container backend.     |
| **Application Access**  | Host Browser      | Access via `localhost:8080`.                    |

**Benefits:** Clean separation, no host machine dependency conflicts, portable environment.

**Next Steps:** For better reproducibility, convert this setup into a `.devcontainer` configuration. For team/cloud collaboration, consider **DevPod**.

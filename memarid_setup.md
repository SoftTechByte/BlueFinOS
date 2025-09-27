# 🐧 Mermaid CLI on Bluefin OS (Immutable Fedora)

Mermaid CLI (`mmdc`) lets you convert plain-text diagrams (Mermaid syntax) into **PNG / SVG / PDF**.  
On **Bluefin OS** (Fedora Silverblue/Kinoite family), `dnf` is restricted, so you need a **user-space only setup**.  
This guide shows you how to:  
1. Set up Mermaid CLI on Bluefin.  
2. Run a proof-of-concept diagram.  
3. Learn the basics of the Mermaid language to start drawing your own diagrams.  

---

## 1️⃣ Setup & Proof of Concept (POC)

### Step 1: Install Mermaid CLI with Homebrew
```bash
brew install mermaid-cli
Step 2: Install Chromium with Puppeteer
Mermaid CLI depends on Puppeteer, which needs Chromium. Install it into your home directory:

bash
Copy code
npx puppeteer browsers install chrome
👉 This will download Chromium into:

bash
Copy code
~/.cache/puppeteer/
Step 3: Point Mermaid CLI to Chromium
Export the path to Chromium so mmdc can find it:

bash
Copy code
export PUPPETEER_EXECUTABLE_PATH="$(find ~/.cache/puppeteer -type f -name chrome -o -name chrome-headless-shell | head -n 1)"
Check:

bash
Copy code
echo $PUPPETEER_EXECUTABLE_PATH
Step 4: Create a Test Diagram
Make a file test.mmd:

mermaid
Copy code
flowchart TD
  A[Artificial Intelligence] --> B[Machine Learning]
  B --> C[Generative AI]
  C --> D[Foundation Models]
  D --> E[Applications]
Step 5: Render It
bash
Copy code
mmdc -i test.mmd -o test.png
🎉 Now you’ll see test.png — your first Mermaid diagram!

2️⃣ Mermaid Language Quickstart
Mermaid uses a domain-specific language (DSL) for diagrams.
You don’t need to learn JavaScript — just simple text syntax.

Here are some examples you can copy into .mmd files:

🔹 Example 1: Flowchart
mermaid
Copy code
flowchart TD
  A[Start] --> B{Condition?}
  B -->|Yes| C[Do Something]
  B -->|No| D[Do Nothing]
  C --> E[End]
  D --> E[End]
🔹 Example 2: Sequence Diagram
mermaid
Copy code
sequenceDiagram
  participant User
  participant System

  User->>System: Request
  System-->>User: Response
🔹 Example 3: Class Diagram
mermaid
Copy code
classDiagram
  class Car {
    +String brand
    +drive()
  }
  class ElectricCar {
    +int batteryLevel
    +charge()
  }
  Car <|-- ElectricCar
🔹 Example 4: Gantt Chart
mermaid
Copy code
gantt
  dateFormat  YYYY-MM-DD
  title Project Plan
  section Phase 1
  Setup :done,    des1, 2024-01-01,2024-01-05
  section Phase 2
  Development :active, des2, 2024-01-06, 10d
3️⃣ Make Setup Permanent
Add the Chromium export line to your shell config (~/.bashrc or ~/.zshrc):

bash
Copy code
echo 'export PUPPETEER_EXECUTABLE_PATH="$(find ~/.cache/puppeteer -type f -name chrome -o -name chrome-headless-shell | head -n 1)"' >> ~/.bashrc
Reload:

bash
Copy code
source ~/.bashrc
Optional: Add an alias to simplify usage:

bash
Copy code
echo 'alias mermaid="mmdc -i"' >> ~/.bashrc
Now you can run:

bash
Copy code
mermaid test.mmd -o test.png
🧹 Cleanup
To remove everything:

bash
Copy code
brew uninstall mermaid-cli
rm -rf ~/.cache/puppeteer
💡 Why This Approach?
Works fully in user space → no system pollution.

Perfect for immutable Fedora systems like Bluefin OS.

Easy to remove or reinstall.

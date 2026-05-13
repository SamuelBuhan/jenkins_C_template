# Jenkins CI Template for C Projects

A beginner-friendly template and tutorial for building C projects with Jenkins declarative pipelines.

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Pipeline Overview](#pipeline-overview)
3. [How to Test Locally (without Jenkins)](#how-to-test-locally-without-jenkins)
4. [How to Run with Jenkins](#how-to-run-with-jenkins)
   - [Option A: Jenkins in Docker (recommended)](#option-a-jenkins-in-docker-recommended)
   - [Option B: Jenkins installed locally](#option-b-jenkins-installed-locally)
5. [Customising the Template](#customising-the-template)
6. [Common Errors](#common-errors)

---

## Project Structure

```
.
├── Jenkinsfile          # Pipeline definition — Jenkins reads this automatically
├── src/
│   ├── main.c           # Entry point
│   ├── math_utils.c     # Example library source
│   └── math_utils.h     # Example library header
└── tests/
    └── test_math_utils.c  # Tests (compiled and run in the Test stage)
```

Add your own `.c` / `.h` files under `src/`. Add test files under `tests/`. The pipeline picks them up automatically.

---

## Pipeline Overview

The `Jenkinsfile` defines five stages:

| Stage | What happens |
|---|---|
| **Checkout** | Jenkins clones/pulls your repository |
| **Setup** | Creates the `build/` output directory |
| **Build** | Compiles `src/*.c` into `build/app` using `gcc` |
| **Test** | Compiles `tests/*.c` + library sources into `build/test_runner` and runs it |
| **Archive** | Saves `build/` artifacts so you can download them from the Jenkins UI |

After every run (pass or fail) the `build/` directory is cleaned up.

---

## How to Test Locally (without Jenkins)

You do not need Jenkins installed to verify the build works. Run the same commands Jenkins would run:

```bash
# 1. Build
mkdir -p build
gcc -Wall -Wextra -O2 -o build/app src/*.c

# 2. Run the app
./build/app

# 3. Build and run tests
LIB_SRCS=$(find src -name "*.c" ! -name "main.c")
gcc -Wall -Wextra -O2 -o build/test_runner tests/*.c $LIB_SRCS
./build/test_runner

# 4. Clean up
rm -rf build/
```

Expected output:

```
# app:
2 + 3 = 5

# test_runner:
PASS: add(2, 3) == 5
PASS: add(0, 0) == 0
PASS: add(-1, 1) == 0
All tests passed.
```

---

## How to Run with Jenkins

### Option A: Jenkins in Docker (recommended)

This is the fastest way to get Jenkins running without installing it on your machine.

**Prerequisites:** [Docker](https://docs.docker.com/get-docker/) installed.

```bash
# 1. Start Jenkins
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts

# 2. Get the initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Then open http://localhost:8080, paste the password, and follow the setup wizard.

> **Note:** The Jenkins Docker image does not include `gcc` by default. Install it inside the container:
> ```bash
> docker exec -u root jenkins apt-get update && apt-get install -y gcc
> ```
> Or use a custom agent image that already has a C toolchain (see [Customising the Template](#customising-the-template)).

**Push your code to GitHub (or another Git host), then:**

1. Click **New Item** → enter a name → select **Pipeline** → click OK.
2. Under **Pipeline**, set **Definition** to `Pipeline script from SCM`.
3. Set **SCM** to `Git` and paste your repository URL.
4. Set **Script Path** to `Jenkinsfile`.
5. Click **Save**, then **Build Now**.

---

### Option B: Jenkins installed locally

**macOS (Homebrew):**

```bash
brew install jenkins-lts gcc
brew services start jenkins-lts
```

Open http://localhost:8080 and follow the setup wizard.

**Ubuntu/Debian:**

```bash
# Install Java (Jenkins requirement)
sudo apt-get install -y openjdk-17-jdk gcc

# Add Jenkins repo and install
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update && sudo apt-get install -y jenkins
sudo systemctl start jenkins
```

Initial password:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Then create a Pipeline job pointing at this repository (same steps as Option A above).

---

## Customising the Template

### Use a Docker agent (recommended for reproducibility)

Replace `agent any` with a Docker image that has GCC pre-installed:

```groovy
agent {
    docker { image 'gcc:latest' }
}
```

This avoids having to install `gcc` on the Jenkins host.

### Use Make

Replace the Build and Test `sh` steps with:

```groovy
stage('Build') {
    steps {
        sh 'make'
    }
}

stage('Test') {
    steps {
        sh 'make test'
    }
}
```

### Use CMake

```groovy
stage('Build') {
    steps {
        sh 'cmake -B build && cmake --build build'
    }
}
```

### Change compiler flags

Edit the `CFLAGS` environment variable at the top of the `Jenkinsfile`:

```groovy
environment {
    CFLAGS = '-Wall -Wextra -Werror -O2 -std=c11'
}
```

### Notify on failure (email or Slack)

Add to the `post` block:

```groovy
post {
    failure {
        mail to: 'you@example.com',
             subject: "Build failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
             body: "See ${env.BUILD_URL}"
    }
}
```

---

## Common Errors

| Error | Cause | Fix |
|---|---|---|
| `gcc: command not found` | `gcc` not installed on the agent | Install `gcc` or use `agent { docker { image 'gcc:latest' } }` |
| `multiple definition of 'main'` | `main.c` included in test build | The pipeline already excludes it; check your test file does not also define `main` twice |
| `No such file or directory: src/*.c` | `src/` directory missing | Create `src/` and add at least one `.c` file |
| Pipeline stuck at "Waiting for next available executor" | No agent is online | Make sure the Jenkins node/agent is connected and has available executors |
| `archiveArtifacts` fails | `build/` was cleaned before archiving | The `always` post-step cleans up — archiving happens in a stage **before** post |

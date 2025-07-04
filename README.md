# README.md

# Node.js Docker Development Environment

This repository provides a **robust and powerful Docker development environment** for any Node.js project (VanilaJS,
React, Vue, VuePress, Svelte, Express, etc.).

It's designed to be smart, fast, and easy to use, automating common tasks and handling complex issues like file
permissions and service orchestration out of the box. This setup is engineered to provide a professional-grade workflow
for development, ensuring consistency and ease of use for individual developers and teams.

## Prerequisites

Before you begin, ensure you have the following installed on your system:

- **Docker**
- **Docker Compose**
- **make**

## Quick Start

Getting started is designed to be as simple as possible.

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd node-docker
   ```

2. **Initialize the environment:**
   ```bash
   make init
   ```
   This single command is all you need. It's smart and will:
    - **Automatically create your `.env` file** from the `.env.example` template on the first run.
    - **Detect if you're starting a new project** and launch an interactive setup session. Inside this session, create
      your project (e.g., `npm create vuepress@next .`). After exiting, `make` will prompt you to run `make init` again
      to complete the installation.
    - **Or, if a project already exists**, it will perform a full reset: build images, install dependencies, and start
      the background services, preparing everything for development.

3. **Start Developing:**
   ```bash
   make up
   ```
   This command will start the interactive development server. You are now ready to code!

## 🛠️ Daily Workflow & Commands

### Core Commands

- `make init`
  This is the main command for **setting up** or **resetting** the environment. It prepares everything but does not
  start the interactive dev server. Use it when you first clone a project or when you need a clean slate (e.g., after
  changing Docker configurations). After it completes, run `make up`.

- `make up`
  This is your primary command for **starting a work session**. It ensures containers are running and launches the
  interactive development server, showing its output directly in your terminal. Press `Ctrl+C` to stop the dev server.

- `make down`
  Stops all running services cleanly and quickly.

- `make restart`
  Performs a full restart of the development server and environment (equivalent to `make down` and `make up`).

### Utility Commands

- `make shell`
  Opens a `bash` shell inside the **running** `app` container. Use this for tasks that should affect your running
  instance.

- `make node`
  Launches a **new, temporary, clean** container and opens a `bash` shell. Use this for isolated commands, like testing
  a clean `npm install` without affecting your main environment.

- `make install`
  A shortcut to run `npm install` inside a temporary container.

- `make logs`
  Follows the log output of all services.

- `make build`
  Forces a rebuild of all Docker images, pulling the latest base images.

## Configuration

The entire environment is configured through the `.env` file.

- `APP_NAME`: The base name for your Docker project and containers. Defaults to `node-dev`.
- `FRONTEND_URL`: The domain name you'll use to access the application in your browser. Traefik will use this for
  routing. Defaults to `node.app.loc`.
- `DEV_COMMAND`: **The most important variable.** This is the exact command used to start your development server. It's
  pre-configured for `npm run dev` but can be easily changed.

**Example: Adapting for a Create React App project:**
Simply open your `.env` file and change the command:

```dotenv
DEV_COMMAND=npm start
```
That's it! The `make up` command will now correctly start your React application.

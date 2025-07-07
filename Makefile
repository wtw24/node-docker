# Load .env file and export its variables
-include .env
export

# --- Configuration ---
# Pass current user's UID/GID to Docker Compose to avoid permission issues
export HOST_USER_ID := $(shell id -u)
export HOST_GROUP_ID := $(shell id -g)

# Default dev command, if not set in .env.
export DEV_COMMAND ?= npm run dev

# --- Colors ---
BOLD         := \033[1m
COLOR_GREEN  := \033[1;32m
COLOR_YELLOW := \033[1;33m
COLOR_RED    := \033[1;31m
COLOR_DEFAULT:= \033[0m

# --- Main Settings ---
.DEFAULT_GOAL := help

.PHONY: init up down restart docker-up docker-down \
        docker-pull docker-build pre-scripts create-env-file \
        create-networks install dev-server shell node logs app-clear \
        success info help


# ====================================================================================
#  Workflow Commands
# ====================================================================================

## [SMART] Initializes the project. Runs setup for new projects, or resets existing ones.
init:
	@make -s pre-scripts
	@if [ ! -f "src/package.json" ]; then \
		printf "%bProject not found in 'src/'. Running initial setup...%b\n" "$(COLOR_YELLOW)" "$(COLOR_DEFAULT)"; \
		make -s setup; \
	else \
		printf "✓ Project found. Initializing the full environment...\n"; \
		make -s docker-down; \
		make -s docker-build; \
		make -s install; \
		make -s docker-up; \
		make -s success; \
	fi


## [NEW PROJECT] Run interactive session to create a new project.
setup:
	@make -s docker-build
	@make -s app-clear
	@printf "\n%b======================================================================%b\n" "$(COLOR_YELLOW)" "$(COLOR_DEFAULT)"
	@printf "%b          Entering Interactive Project Setup Session%b\n" "$(COLOR_YELLOW)" "$(COLOR_DEFAULT)"
	@printf "%b----------------------------------------------------------------------%b\n" "$(COLOR_YELLOW)" "$(COLOR_DEFAULT)"
	@printf "You are now inside a temporary Docker container's command line.\n"
	@printf "The current directory is '/app', which is linked to your './src' folder.\n"
	@printf "\n  STEP 1: Run your project creation command now.\n"
	@printf "          Example: %bnpm create vuepress@next .%b\n" "$(COLOR_GREEN)" "$(COLOR_DEFAULT)"
	@printf "\n  STEP 2: When finished, type %bexit%b and press Enter to continue.\n" "$(COLOR_YELLOW)" "$(COLOR_DEFAULT)"
	@printf "%b======================================================================%b\n" "$(COLOR_YELLOW)" "$(COLOR_DEFAULT)"
	@make -s node
	@printf "\n%b======================================================================%b\n" "$(COLOR_GREEN)" "$(COLOR_DEFAULT)"
	@printf "%b          Initial Project Files Created Successfully!%b\n" "$(COLOR_GREEN)" "$(COLOR_DEFAULT)"
	@printf "%b----------------------------------------------------------------------%b\n" "$(COLOR_GREEN)" "$(COLOR_DEFAULT)"
	@printf "Your new project files are now in the './src' directory.\n"
	@printf "\n  %bIMPORTANT NEXT STEPS:%b\n" "$(COLOR_YELLOW)" "$(COLOR_DEFAULT)"
	@printf "\n  1. %bEdit the main '.env' file in the project root.%b\n" "$(BOLD)" "$(COLOR_DEFAULT)"
	@printf "     (This is the file located in the same directory as the Makefile).\n"
	@printf "     Ensure the %bDEV_COMMAND%b variable matches your new project's start script.\n" "$(COLOR_YELLOW)" "$(COLOR_DEFAULT)"
	@printf "     (e.g., %bDEV_COMMAND=npm run dev%b, %bDEV_COMMAND=npm start%b, etc.)\n" "$(COLOR_GREEN)" "$(COLOR_DEFAULT)" "$(COLOR_GREEN)" "$(COLOR_DEFAULT)"
	@printf "\n  2. %bRun 'make init' again%b to build the environment and install dependencies.\n" "$(BOLD)" "$(COLOR_DEFAULT)"
	@printf "%b======================================================================%b\n\n" "$(COLOR_GREEN)" "$(COLOR_DEFAULT)"

## Starts the environment without rebuilding.
up: docker-up dev-server

## Stops the environment.
down: docker-down

## Restarts the environment.
restart: down up


# ====================================================================================
#  Internal Steps & Scripts
# ====================================================================================

# -- Docker Wrappers --
docker-up:
	@printf "✓ Starting containers...\n"
	@docker compose up -d

docker-down:
	@printf "✓ Stopping services...\n"
	@docker compose down --remove-orphans -t 1

docker-pull:
	@printf " Pulling latest images...\n"
	@docker compose pull

docker-build:
	@printf "✓ Building services...\n"
	@docker compose build --pull

# -- Script Groups --
pre-scripts: create-env-file create-bash-history-file create-networks

# -- Setup Scripts --
create-env-file:
	@printf "✓ Ensuring .env file exists...\n"
	@docker run --rm -v ${PWD}:/app -w /app -u ${HOST_USER_ID}:${HOST_GROUP_ID} bash:5.2 bash docker/bin/create-env-file.sh

create-bash-history-file:
	@printf "✓ Ensuring .bash_history file exists...\n"
	@docker run --rm -v ${PWD}/:/app -w /app -u ${HOST_USER_ID}:${HOST_GROUP_ID} bash:5.2 bash docker/bin/create-bash_history.sh

create-networks:
	@printf "✓ Ensuring Docker networks exist...\n"
	@docker network create proxy 2>/dev/null || true


# ====================================================================================
#  UTILITY COMMANDS
# ====================================================================================

## Install/update npm dependencies.
install:
	@printf "✓ Installing npm dependencies...\n"
	@docker compose run --rm app npm install

## Run the dev server interactively in the container.
dev-server:
	@make -s info
	@printf "%bStarting development server with command:%b %s ...\n" "$(COLOR_YELLOW)" "$(COLOR_DEFAULT)" "$(DEV_COMMAND)"
	@docker compose exec app sh -c "$(DEV_COMMAND)"

## Enter a bash session in the *running* 'app' container.
shell:
	@docker compose exec app bash

## Run a *new, temporary* container for clean one-off commands.
node:
	@docker compose run --rm app bash

## Follow the logs of all services.
logs:
	@docker compose logs -f


# ====================================================================================
#  INTERNAL HELPER TARGETS
# ====================================================================================

## Clears the 'src' directory.
app-clear:
	@rm -rf src/* src/.* 2>/dev/null || true

# -- Finalization --
success:
	@printf "\n✓%b Environment initialized. Run 'make up' to start the dev server.%b\n\n" "$(COLOR_GREEN)" "$(COLOR_DEFAULT)"

## Displays project URL after start.
info:
	@printf "  %b➜%b  Application: %bhttps://$${FRONTEND_URL:-node.app.loc}%b\n\n" "$(COLOR_YELLOW)" "$(COLOR_DEFAULT)" "$(COLOR_GREEN)" "$(COLOR_DEFAULT)"

## Show this help message.
help:
	@printf "Usage: make [target]\n\n"
	@printf "Available targets:\n"
	@awk ' \
		/^##/{ \
			h=substr($$0, 4); \
			next \
		} \
		{ \
			if (h != "" && $$0 ~ /^[a-zA-Z0-9_-]+:/) { \
				split($$0, t, ":"); \
				printf "  \033[36m%-18s\033[0m %s\n", t[1], h; \
			} \
			h="" \
		} \
	' $(MAKEFILE_LIST) | sort

-include src/Makefile
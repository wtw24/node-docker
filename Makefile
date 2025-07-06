# Load .env file and export its variables
-include .env
export

# --- Configuration ---
# Pass current user's UID/GID to Docker Compose to avoid permission issues
export HOST_USER_ID := $(shell id -u)
export HOST_GROUP_ID := $(shell id -g)

# Default dev command, if not set in .env.
export DEV_COMMAND ?= npm run dev

# --- Colors for beautiful output ---
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
		echo "$(COLOR_YELLOW)Project not found in 'src/'. Running initial setup...$(COLOR_DEFAULT)"; \
		make -s setup; \
	else \
		echo "✓ Project found. Initializing the full environment..."; \
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
	@echo -e ""
	@echo -e "$(COLOR_YELLOW)======================================================================$(COLOR_DEFAULT)"
	@echo -e "$(COLOR_YELLOW)      🚀  Entering Interactive Project Setup Session$(COLOR_DEFAULT)"
	@echo -e "$(COLOR_YELLOW)----------------------------------------------------------------------$(COLOR_DEFAULT)"
	@echo -e "You are now inside a temporary Docker container's command line."
	@echo -e "The current directory is '/app', which is linked to your './src' folder."
	@echo -e ""
	@echo -e "  $(COLOR_DEFAULT)STEP 1: Run your project creation command now.$(COLOR_DEFAULT)"
	@echo -e "          Example: $(COLOR_GREEN)npm create vuepress@next .$(COLOR_DEFAULT)"
	@echo -e ""
	@echo -e "  $(COLOR_DEFAULT)STEP 2: When finished, type $(COLOR_YELLOW)exit$(COLOR_DEFAULT) and press Enter to continue."
	@echo -e "$(COLOR_YELLOW)======================================================================$(COLOR_DEFAULT)"
	@make -s node
	@echo -e ""
	@echo -e "$(COLOR_GREEN)======================================================================$(COLOR_DEFAULT)"
	@echo -e "$(COLOR_GREEN)      🎉  Initial Project Files Created Successfully!$(COLOR_DEFAULT)"
	@echo -e "$(COLOR_GREEN)----------------------------------------------------------------------$(COLOR_DEFAULT)"
	@echo -e "Your new project files are now in the './src' directory."
	@echo -e ""
	@echo -e "  $(COLOR_YELLOW)IMPORTANT NEXT STEPS:$(COLOR_DEFAULT)"
	@echo -e ""
	@echo -e "  $(COLOR_DEFAULT)1. $(BOLD)Edit the main '.env' file in the project root.$(COLOR_DEFAULT)"
	@echo -e "     (This is the file located in the same directory as the Makefile)."
	@echo -e "     Ensure the $(COLOR_YELLOW)DEV_COMMAND$(COLOR_DEFAULT) variable matches your new project's start script."
	@echo -e "     (e.g., $(COLOR_GREEN)DEV_COMMAND=npm run dev$(COLOR_DEFAULT), $(COLOR_GREEN)DEV_COMMAND=npm start$(COLOR_DEFAULT), etc.)"
	@echo -e ""
	@echo -e "  $(COLOR_DEFAULT)2. $(BOLD)Run 'make init' again$(COLOR_DEFAULT) to build the environment and install dependencies."
	@echo -e "$(COLOR_GREEN)======================================================================$(COLOR_DEFAULT)"
	@echo -e ""

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
	@echo -e "✓ Starting containers..."
	@docker compose up -d

docker-down:
	@echo -e "✓ Stopping services..."
	@docker compose down --remove-orphans -t 1

docker-pull:
	@echo -e " Pulling latest images..."
	@docker compose pull

docker-build:
	@echo -e "✓ Building services..."
	@docker compose build --pull

# -- Script Groups --
pre-scripts: create-env-file create-bash-history-file create-networks

# -- Setup Scripts --
create-env-file:
	@echo -e "✓ Ensuring .env file exists..."
	@docker run --rm -v ${PWD}:/app -w /app -u ${HOST_USER_ID}:${HOST_GROUP_ID} bash:5.2 bash docker/bin/create-env-file.sh

create-bash-history-file:
	@echo -e "✓ Ensuring .bash_history file exists..."
	@docker run --rm -v ${PWD}/:/app -w /app -u ${HOST_USER_ID}:${HOST_GROUP_ID} bash:5.2 bash docker/bin/create-bash_history.sh

create-networks:
	@echo -e "✓ Ensuring Docker networks exist..."
	@docker network create proxy 2>/dev/null || true


# ====================================================================================
#  UTILITY COMMANDS
# ====================================================================================

## Install/update npm dependencies.
install:
	@echo -e "✓ Installing npm dependencies..."
	@docker compose run --rm app npm install

## Run the dev server interactively in the container.
dev-server:
	@make -s info
	@echo -e "$(COLOR_YELLOW)Starting development server with command: $(COLOR_YELLOW)$(DEV_COMMAND)$(COLOR_DEFAULT)..."
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
	@echo -e ""
	@echo -e "$(COLOR_GREEN)✓ Environment initialized. Run 'make up' to start the dev server.$(COLOR_DEFAULT)";
	@echo -e ""

## Displays project URL after start.
info:
	@echo -e ""
	@echo -e "  $(COLOR_YELLOW)➜$(COLOR_DEFAULT)  Application: $(COLOR_GREEN)https://$${FRONTEND_URL:-node.app.loc}$(COLOR_DEFAULT)"
	@echo -e ""

## Show this help message.
help:
	@echo -e "Usage: make [target]"
	@echo -e ""
	@echo -e "Available targets:"
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
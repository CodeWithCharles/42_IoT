# ---------------------------------------------------------------------------- #
#                              IoT Part 3 Makefile                             #
# ---------------------------------------------------------------------------- #

include Variables.mk

# -------------------------------- Phony rules ------------------------------- #

all: up clean

up:
	@echo "${YELLOW}Running scripts on Linux ...${NC}"
	@sudo ./scripts/install-dependencies.sh
	@sudo ./scripts/k3d.sh
	@sudo ./scripts/argocd.sh
	@sudo ./scripts/dev.sh

clean:
	@echo "${GREEN}Cleaning up...${NC}"
	@rm -rf ./confs/kubectl
	@rm -rf ./confs/kubectl.sha256
	@echo "$(RED)[CLEAN]  :$(NC) Cleaning project...$(BG_GREEN)\033[47G[✔]$(NC)"

fclean: clean
	@sudo kubectl delete pods -n argocd --all
	@sudo docker system prune -af --volumes
	@sudo k3d cluster delete $(USERNAME)
	@echo "$(RED)[FCLEAN] :$(NC) Full cleaning project...$(BG_GREEN)\033[47G[✔]$(NC)"

.PHONY: all up clean fclean
# ---------------------------------------------------------------------------- #
#                              IoT Part 3 Makefile                             #
# ---------------------------------------------------------------------------- #

include Variables.mk

# -------------------------------- Phony rules ------------------------------- #

all: up clean

up:
	@echo "${YELLOW}Running scripts on Linux ...${NC}"
	@sudo ${SH_DEPS}
	@sudo ${SH_K3D}
	@sudo ${SH_ARGOCD}
	@sudo ${SH_DEV}

clean:
	@echo "${GREEN}Cleaning up...${NC}"
	@rm -rf ./confs/kubectl
	@rm -rf ./confs/kubectl.sha256
	@echo "$(RED)[CLEAN]  :$(NC) Cleaning project...$(BG_GREEN)\033[47G[✔]$(NC)"

fclean: clean
	@sudo kubectl delete pods -n argocd --all
	@sudo kubectl delete pods -n dev --all
	@sudo docker system prune -af --volumes
	@sudo k3d cluster delete $(USERNAME)
	@sudo rm -rf /tmp/42_IoT_Playground_cpoulain
	@echo "$(RED)[FCLEAN] :$(NC) Full cleaning project...$(BG_GREEN)\033[47G[✔]$(NC)"

k-get-ns:
	@sudo kubectl get ns

k-get-pods:
	@sudo kubectl get pods -A

k-get-pods-dev:
	@sudo kubectl get pods -n dev

k-get-pods-argocd:
	@sudo kubectl get pods -n argocd

fetch-dev:
	@curl http://localhost

switch-v1:
	@cd /tmp/42_IoT_Playground_cpoulain && sudo sed -i 's/wil42\/playground\:v2/wil42\/playground\:v1/g' manifests/deployment.yaml && \
	sudo git add . && sudo git commit -a -m "v1" && sudo git push;

switch-v2:
	@cd /tmp/42_IoT_Playground_cpoulain && sudo sed -i 's/wil42\/playground\:v1/wil42\/playground\:v2/g' manifests/deployment.yaml && \
	sudo git add . && sudo git commit -a -m "v2" && sudo git push;

.PHONY: all up clean fclean k-get-ns k-get-pods k-get-pods-dev \
		k-get-pods-argocd fetch-dev switch-v1 switch-v2
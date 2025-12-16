.PHONY: all up down start stop restart status ssh-server ssh-worker clean fclean re help

all:
	./scripts/start.sh

up:
	vagrant up

down:
	vagrant destroy -f

status:
	vagrant status

ssh-server:
	vagrant ssh cpoulainS

clean:
	rm -f node-token
	rm -f k3s.yaml

fclean: down clean
	rm -rf .vagrant

# Rebuild everything
re: fclean all

help:
	@echo "IoT Project - K3s Cluster Makefile"
	@echo "==================================="
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all         - Create and start the cluster (default)"
	@echo "  up          - Create and provision VMs"
	@echo "  down        - Destroy all VMs"
	@echo "  status      - Show VM status"
	@echo "  ssh-server  - SSH into cpoulainS (server)"
	@echo "  ssh-worker  - SSH into cpoulainSW (worker)"
	@echo "  clean       - Remove temporary files"
	@echo "  fclean      - Destroy VMs and clean all files"
	@echo "  re          - Rebuild everything from scratch"
	@echo "  help        - Show this help message"

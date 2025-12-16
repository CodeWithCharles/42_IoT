# IoT - Inception of Things - Projet 42

### P1 - Introduction a Vagrant et Kubernetes

#### Objectif de cette partie : 

 * Mettre en place, de maniere reproductible et automatisee, une infra minimale basee sur Kubernetes (via K3s) a l'aide de Vagrant.\
 * Le but ici est de pouvoir mettre en place en une commande, un environnement.\

##### Pourquoi Vagrant ? 

Vagrant est un orchestrateur de virtualisation, c'est a dire qu'il permet la creation et configuration de machines virtuelles de maniere declarative.\

Au lieu de dire a quelqu'un :\
    * Installe cet OS\
    * Cree un VM\
    * Configure le reseau\
    * Installe Docker\
    * Installe Kubernetes\
 
On va le decrire dans un fichier unique `(Vagrantfile)`. Vagrant se charge du reste : \
    Les avantages : \
        * Meme environnement de travail pour tout le monde\
        * Moins de "Works on my machine T_T"\
        * Destruction, recreation propre des VMs `(vagrant destroy)`\
        * Versionnable via Git (a voir dans la P3).\

==> Dans ce projet, Vagrant sert de socle pour deployer automatiquement les VMs necessaires a K3s.\

##### Pourquoi K3s ?

K3s est une distro Kubernetes legere, maintenue par Rancher.\

Kubernetes "classique" aurait ete trop lourd et trop verbeux pour ce type de projet, K3s est explicitement demande par le sujet.\

K3s retire :\
    * la complexite inutile\
    * un grand nombre de dependances\

K3s toutefois garde : \
    * l'API Kubernetes\
    * les concepts cles : pods, services, nodes ...\

Resultant : \
    * En une installation rapide\
    * En une consommation de ressources maitrisee et faible\
    * Une adaptation parfaite a une VM locale\

Dans ce projet, **K3s fournit le cluster Kubernetes** sur lequel les etapes suivantes (p2, p3) du projet IoT vont s'appuyer\

##### Architecture generale : 

###### Vagrantfile : 

Le `Vagrantfile` est le point d'entree du projet : \

Il definit : \
    * La box de base (OS de la VM), pour la P1 et la P2, l'image choisie est bento/debian-13, des iso maintenue par Chef.io, lightweight, parfaitement adaptee a ce type d'infrastructure.\
    * La configuration systeme\
    * L'installation des dependances\
    * L'installation de K3s + `kubectl`\

###### install.sh

Ce script est un **socle commun** qui sera joue sur toutes les machines a chaque creation de VM grace au `trigger` dans le Vagrantfile.\
Il permet de :\
    * Mettre a jour le systeme hote\
    * Verifier l'installation des dependances de bases necessaires au projet et remonter en sommaire les erreurs et warnings lies au projet\
    * S'assurer que la machine hote a les ressources necessaires au projet\
    * Preparer l'environnement pour Kubernetes\

###### install_k3s_server.sh

Ce script installe et configure le **serveur K3s**.\
Il permet est responsable de : \
    * L'installation de K3s en mode serveur\
    * L'init du cluster Kubernetes\
    * Generer le token necessaires aux agents pour rejoindre le cluster\
Ce noeud joue le role de **control plane**:\
    * Gestion de l'etat du cluster\
    * Orchestration des workloads\
    * exposition de l'API Kubernetes\

Sans ce script d'installation, pas de cluster.\

###### install_k3s_agent.sh

Ce script est execute sur les noeuds agents.\
Son role : \
    * Installer K3s en mode agent\
    * Se connecter au serveur K3s existant\
    * Rejoindre le cluster a l'aide du token\
Les agents : \
    * N'heberge pas l'API Kubernetes\
    * Executent les pods\
    * Fournissent la capacite de calcul\
Ils sont interchangeables et scalables.\

###### install_kubectl.sh

Ce script installe **kubectl**, l'outil CLI qui permet d'interagir avec Kubernetes\

Il permet : \
    * De verifier l'etat du cluster\
    * De lister les nodes, pods, services\
    * Deployer des ressources Kubernetes\

#### Ordre d'execution logique : 

1. Vagrant cree les machines virtuelles\
2. `install.sh` verifie le systeme\
3. `install_k3s_server.sh` init le cluster\
4. `install_k3s_agent.sh` rattache les agents\
5. `install_kubectl.sh` permet l'administration\

Chaque script a un role precis, c'est volontaire d'eviter tant que possible l'inline shell dans le Vagrantfile\

#### Resultat attendu :

A la fin du provisionning : \
    * Les VMs sont fonctionnelles\
    * K3s est installe est operationnel\
    * le cluster Kubernetes est joignable \
    * les nodes apparaissent correctement\

### P2

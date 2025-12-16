# IoT - Inception of Things - Projet 42

### P1 - Introduction a Vagrant et Kubernetes

#### Objectif de cette partie : 

 - Mettre en place, de maniere reproductible et automatisee, une infra minimale basee sur Kubernetes (via K3s) a l'aide de Vagrant.
 - Le but ici est de pouvoir mettre en place en une commande, un environnement.

##### Pourquoi Vagrant ? 

Vagrant est un orchestrateur de virtualisation, c'est a dire qu'il permet la creation et configuration de machines virtuelles de maniere declarative.

Au lieu de dire a quelqu'un :\
    - Installe cet OS\
    - Cree un VM\
    - Configure le reseau\
    - Installe Docker\
    - Installe Kubernetes
 
On va le decrire dans un fichier unique `(Vagrantfile)`. Vagrant se charge du reste : \
    Les avantages : \
        - Meme environnement de travail pour tout le monde\
        - Moins de "Works on my machine T_T"\
        - Destruction, recreation propre des VMs `(vagrant destroy)`\
        - Versionnable via Git (a voir dans la P3).

==> Dans ce projet, Vagrant sert de socle pour deployer automatiquement les VMs necessaires a K3s.\

##### Pourquoi K3s ?

K3s est une distro Kubernetes legere, maintenue par Rancher.

Kubernetes "classique" aurait ete trop lourd et trop verbeux pour ce type de projet, K3s est explicitement demande par le sujet.

K3s retire :\
    - la complexite inutile\
    - un grand nombre de dependances

K3s toutefois garde : \
    - l'API Kubernetes\
    - les concepts cles : pods, services, nodes ...

Resultant : \
    - En une installation rapide\
    - En une consommation de ressources maitrisee et faible\
    - Une adaptation parfaite a une VM locale

Dans ce projet, **K3s fournit le cluster Kubernetes** sur lequel les etapes suivantes (p2, p3) du projet IoT vont s'appuyer

##### Architecture generale : 

##### Vagrantfile : 

Le `Vagrantfile` est le point d'entree du projet : 

Il definit : \
    - La box de base (OS de la VM), pour la P1 et la P2, l'image choisie est bento/debian-13, des iso maintenue par Chef.io, lightweight, parfaitement adaptee a ce type d'infrastructure.\
    - La configuration systeme\
    - L'installation des dependances\
    - L'installation de K3s + `kubectl`

##### install.sh

Ce script est un **socle commun** qui sera joue sur toutes les machines a chaque creation de VM grace au `trigger` dans le Vagrantfile.\
Il permet de :\
    - Mettre a jour le systeme hote\
    - Verifier l'installation des dependances de bases necessaires au projet et remonter en sommaire les erreurs et warnings lies au projet\
    - S'assurer que la machine hote a les ressources necessaires au projet\
    - Preparer l'environnement pour Kubernetes

##### install_k3s_server.sh

Ce script installe et configure le **serveur K3s**.\
Il permet est responsable de : \
    - L'installation de K3s en mode serveur\
    - L'init du cluster Kubernetes\
    - Generer le token necessaires aux agents pour rejoindre le cluster\
Ce noeud joue le role de **control plane**:\
    - Gestion de l'etat du cluster\
    - Orchestration des workloads\
    - exposition de l'API Kubernetes

Sans ce script d'installation, pas de cluster.\

##### install_k3s_agent.sh

Ce script est execute sur les noeuds agents.\
Son role : \
    - Installer K3s en mode agent\
    - Se connecter au serveur K3s existant\
    - Rejoindre le cluster a l'aide du token\
Les agents : \
    - N'heberge pas l'API Kubernetes\
    - Executent les pods\
    - Fournissent la capacite de calcul\
Ils sont interchangeables et scalables.

##### install_kubectl.sh

Ce script installe **kubectl**, l'outil CLI qui permet d'interagir avec Kubernetes\

Il permet : \
    - De verifier l'etat du cluster\
    - De lister les nodes, pods, services\
    - Deployer des ressources Kubernetes

#### Ordre d'execution logique : 

1. Vagrant cree les machines virtuelles
2. `install.sh` verifie le systeme
3. `install_k3s_server.sh` init le cluster
4. `install_k3s_agent.sh` rattache les agents
5. `install_kubectl.sh` permet l'administration

Chaque script a un role precis, c'est volontaire d'eviter tant que possible l'inline shell dans le Vagrantfile\

#### Resultat attendu :

A la fin du provisionning : \
    - Les VMs sont fonctionnelles\
    - K3s est installe est operationnel\
    - le cluster Kubernetes est joignable \
    - les nodes apparaissent correctement

### P2 On pousse plus loin le deploiement

#### Architecture generale : 

L'infra repose sur 4 VMs reliees entre elles : 

1. Un serveur Kubernetes (k3s)
2. 1 agent Kubernetes (app1)
3. 1 agent Kubernetes (app2) avec 3 replicas
4. 1 agent Kubernetes (app3) qui sera l'app par defaut si on ne specifie pas l'hostname

Ces machines forment un cluster Kubernetes unique. Toutes les apps sont deployees sur ce cluster et partage les memes ressources reseau.

Le serveur Kubernetes est responsable de : \
    - La gestion d'etat du cluster \
    - L'ochestration des containers \
    - L'exposition des app via un point d'entree unique
Les agents executent concretement les containers applicatifs.

#### Applications deployees : 

Il s'agit de 3 applications web `app1 : 1 replique`, `app2 : 3 repliques`, `app3 : 1 replique`.

Chaque application : \
    - Est deployee via un `Deployment.yaml`\
    - Est exposee a l'interieur du cluster via un `Service.yaml`\
    - Possede son propre contenu HTML injecte via un `ConfigMap`
L'acces aux applications se fait par nom de domaine grace a un `Ingress.yaml` qui agit comme un routeur HTTP.

#### Pourquoi plusieurs repliques pour l'application 2 ? 

L'application 2 est volontairement deployee avec 3 repliques afin d'illustrer plusieurs concepts cles de Kubernetes. 

##### 1. Haute disponibilite
Si un pod tombe (crash, redemarrage, probleme reseau), les autres continuent de repondre. L'application reste accessible sans interruption visible pour l'utilisateur.

##### 2. Repartition de charge
Le `Service` associe a l'app2 repartit automatiquement les requetes entrantes entre les differents pods.

Resultat: \
    - Moins de charge par container\
    - Meilleure reactivite de l'app\
    - Aucun besoin de le gerer manuellement

##### 3. Scalabilite
Changer le nombre de repliques se fait simplement en modifiant une valeur dans le `Deployment`.

Cela permet de : \
    - Absorber davantage de trafic\
    - S'adapter rapidement a un besoin metier\
    - Nul besoin de redeployer toute l'infra, on redeploie le pod concerne

#### Un point d'entree unique : l'Ingress

Un seul Ingress est utilise pour exposer les 3 apps.\

Son role : \
    - Inspecter le nom de domaine de la requete \
    - Rediriger vers le bon `Service`
Exemples: \
    - `app1.com` -> Application 1\
    - `app2.com` -> Application 2\
    - Requete par defaut -> Application 3
Ce qui permet : \
    - Un point d'entree unique\
    - Plusieurs applications derriere une meme infra \
    - Une configuration claire et centralisee

#### Conclusion de la P2 :

Cette partie permet de mettre en evidence : \
    - Le fonctionnement d'un cluster Kubernetes multi nodes\
    - Le deploiement de plusieurs apps sur un meme cluster\
    - L'interet des replicas pour dispo et charge \
    - Separation entre : \
     * Deploiement applicatif \
     * Exposition reseau \
     * Configuration applicative

Kubernetes montre ici son interet principal : **orchestrer proprement ce qui serait vite ingerable si tout devait etre ochestre a la main**

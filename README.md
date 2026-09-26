# Infrastructure 3-Tiers Automatisée sur OpenStack

Déploiement automatisé d'une architecture réseau 3-tiers (Web / App / BDD) sur un cloud privé OpenStack, entièrement pilotée par Infrastructure as Code (Terraform) et Configuration as Code (Ansible).
 
## Objectif
 
Remplacer la création manuelle des ressources OpenStack (réseau, sous-réseau, routeur, security groups, instances) et la configuration manuelle des services par du code déclaratif, reproductible et versionné.
 
## Architecture
 
| Composant | Rôle | Adresse | Accès |
|---|---|---|---|
| `vm-web` | Nginx (reverse proxy) | IP flottante + 10.20.0.44 | HTTP (80) depuis `0.0.0.0/0` |
| `vm-app` | Backend Flask (gunicorn, port 5000) | 10.20.0.17 | Port 5000 uniquement depuis `vm-web` |
| `vm-bdd` | MySQL | 10.20.0.84 | Port 3306 uniquement depuis `vm-app` |
| Réseau | Sous-réseau privé `net-3tiers-private` (VXLAN) + routeur `net-3tiers-router` (gateway externe) | — | — |
 
`vm-web` est la seule instance exposée (IP flottante) ; `vm-app` et `vm-bdd` ne sont joignables que depuis le tier qui les précède, via les security groups `sg-web` / `sg-app` / `sg-bdd`.
 
## Stack technique
 
- **Terraform** — provisioning de l'infrastructure (réseau, sous-réseau, routeur, security groups, instances, IP flottante)
- **Ansible** — configuration des services à l'intérieur des VMs (un playbook par tier)
- **OpenStack (Kolla-Ansible, all-in-one)** — plateforme cloud sous-jacente
## Structure du dépôt
 
```
net-3tiers-automation/
├── terraform/          # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── ansible/             # Configuration des VMs
│   ├── ansible.cfg
│   ├── inventory.ini
│   ├── site.yml         # playbook principal (inclut web.yml / app.yml / db.yml)
│   ├── web.yml
│   ├── app.yml
│   ├── db.yml
│   ├── group_vars/
│   └── templates/
├── monitoring/          # Prometheus + Grafana — non déployé (VM hôte à court de ressources)
└── docs/                # Rapports techniques
```
 
## Prérequis
 
Un environnement OpenStack (Kolla-Ansible all-in-one ou équivalent) déjà déployé et accessible, avec :
 
| Prérequis | Détail |
|---|---|
| Réseau externe *provider* | `public` (flat, `physnet1`, sous-réseau 10.0.2.0/24, pool d'IP flottantes 10.0.2.100–200, sans DHCP) |
| Image | `ubuntu-22.04` (cloud image Jammy) |
| Gabarit (*flavor*) | `m1.small` (2 Go RAM / 10 Go disque / 1 vCPU) |
| Paire de clés | `net-3tiers-key` (générée avec `openstack keypair create`) |
| Client CLI | `python-openstackclient` installé, `admin-openrc.sh` sourcé |
| Outils locaux | Terraform ≥ 1.16, Ansible, un client SSH |
 
Ces quatre premiers éléments (réseau externe, image, flavor, clé) ne sont pas créés par Terraform : ils doivent exister au préalable dans le projet OpenStack cible.
 
## Installation et déploiement
 
### 1. Cloner le dépôt
 
```bash
git clone https://github.com/EmnaBenAli05/private-cloud-openstack.git net-3tiers-automation
cd net-3tiers-automation
```
 
### 2. Provisionner l'infrastructure (Terraform)
 
```bash
source /etc/kolla/admin-openrc.sh   # ou l'openrc du projet OpenStack cible
cd terraform
 
terraform init
terraform plan
terraform apply
```
 
`terraform apply` crée le réseau privé, le routeur, les 3 security groups, les 3 instances et l'IP flottante (23 ressources au total). Récupérer l'IP flottante attribuée :
 
```bash
terraform output
```
 
### 3. Configurer l'accès SSH aux instances
 
`vm-app` et `vm-bdd` n'ont pas d'IP flottante : elles se joignent via `vm-web` comme hôte relais. Ajouter dans `~/.ssh/config` (adapter l'IP flottante et le chemin de la clé) :
 
```
Host vm-web
    HostName <IP_FLOTTANTE>
    User ubuntu
    IdentityFile ~/.ssh/net-3tiers-key
 
Host vm-app
    HostName 10.20.0.17
    User ubuntu
    ProxyJump vm-web
    IdentityFile ~/.ssh/net-3tiers-key
 
Host vm-bdd
    HostName 10.20.0.84
    User ubuntu
    ProxyJump vm-web
    IdentityFile ~/.ssh/net-3tiers-key
```
 
Vérifier l'accès :
 
```bash
ssh vm-web "echo OK web"
ssh vm-app "echo OK app"
ssh vm-bdd "echo OK bdd"
```
 
### 4. Déployer la configuration (Ansible)
 
```bash
cd ../ansible
 
# Test de connectivite
ansible all -i inventory.ini -m ping
 
# Deploiement complet (les 3 tiers)
ansible-playbook -i inventory.ini site.yml
 
# Ou tier par tier
ansible-playbook -i inventory.ini site.yml --limit web
ansible-playbook -i inventory.ini site.yml --limit app
ansible-playbook -i inventory.ini site.yml --limit db
```
 
### 5. Vérifier le déploiement
 
```bash
openstack server list
ssh vm-app "curl -i http://127.0.0.1:5000/health"
```
 
## Réutilisation sur un autre environnement OpenStack
 
Ce projet est conçu pour être rejoué sur n'importe quel projet OpenStack disposant des prérequis ci-dessus :
 
1. Créer le réseau externe, l'image, le flavor et la paire de clés attendus (ou adapter leurs noms dans `terraform/variables.tf`)
2. Adapter si besoin les plages d'adresses (`variables.tf`) et les règles des security groups à l'architecture cible
3. Relancer `terraform init && terraform apply` : les adresses IP des instances peuvent changer, il faut alors mettre à jour `~/.ssh/config` et `ansible/inventory.ini` en conséquence
4. Rejouer les playbooks Ansible (`ansible-playbook -i inventory.ini site.yml`) — ils sont idempotents et peuvent être exécutés plusieurs fois sans effet de bord

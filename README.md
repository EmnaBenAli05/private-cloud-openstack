# Infrastructure 3-Tiers Automatisée sur OpenStack

Déploiement automatisé d'une architecture réseau multi-tiers (Web / App / BDD) sur un cloud privé OpenStack, entièrement pilotée par Infrastructure as Code (Terraform) et configuration as Code (Ansible).

## Objectif

Remplacer la création manuelle de ressources OpenStack (réseau, sous-réseau, routeur, security groups, instances) par du code déclaratif, reproductible et versionné.

## Architecture

| Composant | Rôle | Accès |
|---|---|---|
| VM Web | Nginx/Apache — frontend | HTTP/HTTPS (80/443) depuis 0.0.0.0/0 |
| VM App | Backend applicatif | HTTP (5000/8080) uniquement depuis VM Web |
| VM BDD | MySQL | Port 3306 uniquement depuis VM App |
| Réseau | Sous-réseau privé + routeur virtuel + NAT externe | — |

## Stack technique

- **Terraform** — provisioning de l'infrastructure (réseau, sous-réseau, routeur, security groups, instances)
- **Ansible** — configuration des services à l'intérieur des VMs
- **OpenStack (Kolla-Ansible, all-in-one)** — plateforme cloud sous-jacente

## Structure du dépôt
net-3tiers-automation/
├── terraform/ # Infrastructure as Code
├── ansible/ # Configuration des VMs
├── monitoring/ # Prometheus + Grafana
└── docs/ # Guide d'installation

## Utilisation
```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

variable "auth_url" {
  description = "URL d'authentification Keystone"
  type        = string
  default     = "http://10.0.2.250:5000/v3"
}

variable "user_name" {
  description = "Utilisateur OpenStack"
  type        = string
  default     = "admin"
}

variable "password" {
  description = "Mot de passe OpenStack (voir /etc/kolla/passwords.yml)"
  type        = string
  sensitive   = true
}

variable "tenant_name" {
  description = "Projet OpenStack"
  type        = string
  default     = "admin"
}

variable "external_network_name" {
  description = "Nom du réseau externe/provider déjà existant dans Neutron"
  type        = string
  default     = "public"
}

variable "image_name" {
  description = "Nom de l'image Glance à utiliser pour les instances"
  type        = string
  default     = "ubuntu-22.04"
}

variable "flavor_name" {
  description = "Flavor OpenStack pour les instances"
  type        = string
  default     = "m1.small"
}

variable "key_pair_name" {
  description = "Nom de la paire de clés SSH OpenStack"
  type        = string
  default     = "net-3tiers-key"
}

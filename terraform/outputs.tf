output "vm_web_ip" {
  value = openstack_compute_instance_v2.vm_web.access_ip_v4
}

output "vm_app_ip" {
  value = openstack_compute_instance_v2.vm_app.access_ip_v4
}

output "vm_bdd_ip" {
  value = openstack_compute_instance_v2.vm_bdd.access_ip_v4
}

output "web_floating_ip" {
  value = openstack_networking_floatingip_v2.web_fip.address
}

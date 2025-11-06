output "custom_image_name" {
    description = "Name of the custom image"
    value =  docker_image.c-image.name
}

output "container_name" {
    description = "name of the container"
    value = docker_container.d-custom-cont.name
}

output "container_id" {
    description = "id of the container"
    value = docker_container.d-custom-cont.id
}

# Show the container's internal IP (within Docker network)
output "container_ip" {
  description = "Container IP address inside Docker network"
  value       = docker_container.d-custom-cont.network_data[0].ip_address
}

# Show the port mapping
output "web_port" {
  description = "External port for noVNC web access"
  value       = docker_container.d-custom-cont.ports[0].external
}

# Construct a handy web access URL
output "access_url" {
  description = "URL to access the noVNC LXDE desktop"
  value       = "http://localhost:${docker_container.d-custom-cont.ports[0].external}"
}


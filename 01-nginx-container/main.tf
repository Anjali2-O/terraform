terraform{
    required_providers{
        docker = {
            source = "kreuzwerker/docker"
            version = "~> 3.0"
        }
    }
}

provider "docker" {}

# create a custom docker network
resource "docker_network" "custom_net" {
    name = "tf-custom-net"
}

# create a custom docker volume
resource "docker_volume" "custom_vol" {
    name = "tf-custom-vol"
}

# pull docker image
resource "docker_image" "nginx" {
  name = "nginx:latest"
}

#Copy local file into container volume
resource "null_resource" "copy_html" {
    provisioner "local-exec" {
        command = "docker cp index.html ${docker_container.nginx_server.name}:/usr/share/nginx/html/index.html"
    }

    depends_on = [ docker_container.nginx_server ]
}

# Run nginx container
resource "docker_container" "nginx_server" {
    name = "nginx-server"
    image = docker_image.nginx.name
    
    networks_advanced {
      name = docker_network.custom_net.name
    }

    #mount volume into nginx html folder
    mounts{
        target ="/usr/share/nginx/html"
        source = docker_volume.custom_vol.name
        type = "volume"
    }
    ports{
        internal = 80
        external = 8080
    }
}
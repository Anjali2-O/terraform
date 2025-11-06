terraform{
    required_providers{
        docker = {
            source = "kreuzwerker/docker"
            version = "~> 3.0"
        }
    }
}

provider "docker" {}

resource "docker_image" "custom-nginx" {
    name = "custom-img"

    build{
        context = path.module
        dockerfile = "${path.module}/Dockerfile"
    }
}

resource "docker_network" "custom_net" {
    name = "tfd-custom-net"
}

resource "docker_container" "nginx_cont" {
    name = "custom-container"
    image = docker_image.custom-nginx.name

    networks_advanced {
      name = docker_network.custom_net.name
    }

    ports{
        internal = 80
        external = 8082
    }
}
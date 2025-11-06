terraform{
    required_providers{
        docker = {
            source = "kreuzwerker/docker"
            version = "~> 3.0"
        }
    }
}

provider docker{}

resource "docker_network" "d-net" {
    name = var.network_name
}

resource "docker_image" "c-image"{
    name = var.custom_image

    build{
        context = path.module
        dockerfile = "${path.module}/Dockerfile"
    }
}

resource "docker_container" "d-custom-cont" {
    name = var.container_name
    image = docker_image.c-image.image_id

    networks_advanced {
      name = docker_network.d-net.name
    }

    ports{
        internal = 80
        external = 8081
    }
}
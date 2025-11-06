terraform{
    required_providers{
        docker = {
            source = "kreuzwerker/docker"
            version = "~> 3.0"
        }
    }
}

provider docker{}

resource "docker_network" "multi-net"{
    name = "multi-network"
}

resource "docker_image" "redis" {
    name = "redis:latest"
}

resource "docker_container" "redis-cont" {
    name = "redis-cont"
    image = docker_image.redis.name

    networks_advanced{
        name = docker_network.multi-net.name
    }

    ports{
        internal = 6379
        external = 6379
    }
}

resource "docker_image" "nginx" {
    name = "nginx:latest"
}

resource "docker_container" "nginx-cont" {
    name = "nginx-container"
    image = docker_image.nginx.name

    networks_advanced{
        name = docker_network.multi-net.name
    }

    ports{
        internal =80
        external = 8083
    }

    depends_on = [docker_container.redis-cont]
}
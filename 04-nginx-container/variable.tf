# network name
variable "network_name"{
    description = "docker-network name"
    type = string
    default = "var-net"
}

#nginx image
variable custom_image{
    description = "custom image"
    type = string
    default = "novnc"
}

# container name
variable container_name{
    description = "container name"
    type = string
    default = "novnc-cont"
}
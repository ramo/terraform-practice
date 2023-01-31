provider "docker" {
  host     = "ssh://admin@docker-host:22"
  ssh_opts = ["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"]
}

# Start a container
resource "docker_container" "httpd" {
    name  = "foo"
    image = docker_image.httpd.image_id
    hostname = "webserver"
    ports {
      internal = 80
      external = 80
    }
}
  
# Find the latest httpd image.
resource "docker_image" "httpd" {
    name = "httpd:latest"
}

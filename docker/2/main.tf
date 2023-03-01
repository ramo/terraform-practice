resource "docker_image" "php-httpd-image" {
  name = "php-httpd:challenge"
  build {
    path = "lamp_stack/php_httpd"
    label = {
      challenge = "second"
    }
  }
}


resource "docker_image" "mariadb-image" {
  name = "mariadb:challenge"
  build {
    path = "lamp_stack/custom_db"
    label = {
      challenge = "second"
    }
  }
}

resource "docker_volume" "mariadb_volume" {
  name = "mariadb-volume"
}

resource "docker_network" "private_network" {
  name = "my_network"
  attachable = true
  labels {
    label = "challenge"
    value = "second"
  }
}

resource "docker_container" "php-httpd" {
  name  = "webserver"
  hostname = "php-httpd"
  image = "php-httpd:challenge"
  networks_advanced {
    name = "my_network"
  }
}

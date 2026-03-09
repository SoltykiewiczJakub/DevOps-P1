# 1. Konfiguracja dostawcy Google Cloud
provider "google" {
  project = "project-900a854b-5db3-4235-aa5"
  region  = "europe-central2"
  zone    = "europe-central2-a"
}

# 2. Tworzenie repozytorium w Artifact Registry
resource "google_artifact_registry_repository" "my_repo" {
  location      = "europe-central2"
  repository_id = "my-docker-repo"
  description   = "Repozytorium na obrazy Dockera"
  format        = "DOCKER"
}

# 3. Reguła Firewall (otwarcie portu 80)
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-traffic"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# 4. Maszyna Wirtualna z Debian 12
resource "google_compute_instance" "debian_vm" {
  name         = "devops-debian-vm"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12" # Czysty Debian
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Przydzielenie zewnętrznego IP
    }
  }

  tags = ["http-server"]

  # Uprawnienia, by maszyna mogła pobrać obraz z Artifact Registry
  service_account {
    scopes = ["cloud-platform"]
  }

  # Skrypt startowy - instaluje Dockera na Debianie i uruchamia aplikację
  metadata_startup_script = <<-EOT
    #!/bin/bash
    # Aktualizacja i instalacja zależności dla Dockera
    apt-get update
    apt-get install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Instalacja Dockera
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # Autoryzacja Dockera do pobierania z GCP Artifact Registry
    gcloud auth configure-docker europe-central2-docker.pkg.dev --quiet
    
    # Uruchomienie kontenera z najnowszą wersją aplikacji
    docker run -d -p 80:80 europe-central2-docker.pkg.dev/[TWÓJ_ID_PROJEKTU_GCP]/my-docker-repo/moja-aplikacja:latest
  EOT
}

# Zwrócenie publicznego IP po zakończeniu tworzenia
output "adres_ip_maszyny" {
  value = google_compute_instance.debian_vm.network_interface.0.access_config.0.nat_ip
}

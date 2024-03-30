user=docker_keycloak
machinectl shell $user@

cd ~
&& mkdir -p data/postgres
&& mkdir docker && cd docker

cp ./docker-compose.yml ~/docker/

cd ~/docker 
docker compose up -d && docker compose logs --follow








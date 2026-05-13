#!/bin/bash
set -e

# Start Jenkins container (idempotent — skips if already running)
if [ "$(docker ps -q -f name=jenkins)" ]; then
    echo "Jenkins is already running."
else
    if [ "$(docker ps -aq -f name=jenkins)" ]; then
        echo "Restarting existing Jenkins container..."
        docker start jenkins
    else
        echo "Starting new Jenkins container..."
        docker run -d \
          --name jenkins \
          -p 8080:8080 \
          -p 50000:50000 \
          -v jenkins_home:/var/jenkins_home \
          jenkins/jenkins:lts
    fi
fi

echo ""
echo "Waiting for Jenkins to start..."
sleep 5

echo ""
echo "Initial admin password:"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null \
    || echo "(Not ready yet — run: docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword)"

echo ""
echo "Open Jenkins at: http://localhost:8080"

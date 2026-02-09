FROM jenkins/jenkins:lts

USER root

# Install Docker CLI, Node.js, and other tools
RUN apt-get update && \
    apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    unzip \
    wget && \
    # Install Docker CLI
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    # Install Node.js 18
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    # Clean up
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Trivy (using direct binary installation to avoid repo issues)
# Install SonarQube Scanner
# Install jest-junit for test reporting

# Copy plugin list
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

# Install Jenkins plugins
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Copy initialization script
COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/

# Set permissions for jenkins user to access Docker socket
RUN usermod -aG docker jenkins || groupadd docker && usermod -aG docker jenkins

# Environment variables
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Xmx2g"
ENV JENKINS_OPTS="--prefix=/"

# Switch back to jenkins user
USER jenkins

# Expose ports
EXPOSE 8080 50000
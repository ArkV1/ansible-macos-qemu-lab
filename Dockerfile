FROM python:3.9-slim

# Install required system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openssh-client \
    sshpass \
    git \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /ansible

# Copy requirements file
COPY requirements.txt .

# Install Python packages
RUN pip install --no-cache-dir -r requirements.txt

# Copy ansible configuration
COPY ansible.cfg .

# Create directory for playbooks
RUN mkdir playbooks

# Set environment variables
ENV ANSIBLE_CONFIG=/ansible/ansible.cfg

# Command to keep container running
CMD ["tail", "-f", "/dev/null"]
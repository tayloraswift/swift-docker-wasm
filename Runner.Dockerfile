FROM tayloraswift/swiftwasm:master

USER root

# Install GitHub Actions Runner dependencies
# libicu and libdigest-sha-perl are commonly required by the runner agent
RUN apt update && apt install -y \
    curl \
    jq \
    libicu-dev \
    libdigest-sha-perl \
    && rm -rf /var/lib/apt/lists/*

# Switch back to the non-root user 'ubuntu' (created in base image)
USER ubuntu
WORKDIR /home/ubuntu

# https://github.com/actions/runner/releases
ARG RUNNER_VERSION="2.331.0"
RUN mkdir actions-runner && cd actions-runner \
    && curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Copy the entrypoint script
COPY --chown=ubuntu:ubuntu Scripts/runner-entrypoint.sh /home/ubuntu/actions-runner/entrypoint.sh
RUN chmod +x /home/ubuntu/actions-runner/entrypoint.sh

WORKDIR /home/ubuntu/actions-runner
ENTRYPOINT ["./entrypoint.sh"]

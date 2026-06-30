# Gas Town sandbox image (upstream pattern).
# https://github.com/gastownhall/gastown
FROM docker/sandbox-templates:claude-code

ARG GO_VERSION=1.25.8
ARG DOLT_VERSION=2.0.7
ARG GASTOWN_REF=v1.2.1

USER root

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    sqlite3 \
    tmux \
    curl \
    ripgrep \
    zsh \
    gh \
    netcat-openbsd \
    tini \
    vim \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" | tar -C /usr/local -xz
ENV PATH="/app/gastown:/usr/local/go/bin:/home/agent/go/bin:${PATH}"

RUN curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
RUN curl -fsSL "https://github.com/dolthub/dolt/releases/download/v${DOLT_VERSION}/install.sh" | bash

RUN mkdir -p /app /gt /gt/.dolt-data && chown -R agent:agent /app /gt

RUN echo 'export PATH="/app/gastown:$PATH"' >> /etc/profile.d/gastown.sh && \
    echo 'export PATH="/app/gastown:$PATH"' >> /etc/zsh/zshenv
RUN echo 'export COLORTERM="truecolor"' >> /etc/profile.d/colorterm.sh && \
    echo 'export COLORTERM="truecolor"' >> /etc/zsh/zshenv
RUN echo 'export TERM="xterm-256color"' >> /etc/profile.d/term.sh && \
    echo 'export TERM="xterm-256color"' >> /etc/zsh/zshenv

RUN git clone --depth 1 --branch "${GASTOWN_REF}" \
    https://github.com/gastownhall/gastown.git /app/gastown-src && \
    chown -R agent:agent /app/gastown-src

USER agent

RUN mkdir -p /app/gastown && \
    cd /app/gastown-src && make build && \
    cp gt /app/gastown/gt

# Cursor Agent CLI (Gastown `cursor` preset)
RUN curl -fsSL https://cursor.com/install | bash

USER root
RUN echo 'export PATH="/home/agent/.local/bin:$PATH"' >> /etc/zsh/zshenv
ENV PATH="/home/agent/.local/bin:/app/gastown:/usr/local/go/bin:/home/agent/go/bin:${PATH}"

USER agent
RUN cursor-agent --version

COPY --chown=agent:agent docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

WORKDIR /gt

ENTRYPOINT ["tini", "--", "/app/docker-entrypoint.sh"]
CMD ["sleep", "infinity"]

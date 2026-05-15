# ── Étape 1 : Build ──
# Image Python 3.12 avec uv pré-installé
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS uv

WORKDIR /app

# Active la compilation bytecode (meilleures performances)
ENV UV_COMPILE_BYTECODE=1

# Mode "copy" pour uv
ENV UV_LINK_MODE=copy

# Copie les fichiers de définition des dépendances
COPY pyproject.toml uv.lock ./

# Installe les dépendances (sans cache mount — compatible tous builders)
RUN uv sync --frozen --no-install-project --no-dev --no-editable

# Copie tout le code source
COPY . .

# Simule un numéro de version (le .git n'est pas disponible dans le build)
ARG SETUPTOOLS_SCM_PRETEND_VERSION=0.0.0
ENV SETUPTOOLS_SCM_PRETEND_VERSION=${SETUPTOOLS_SCM_PRETEND_VERSION}

# Installe le projet lui-même
RUN uv sync --frozen --no-dev --no-editable

# ── Étape 2 : Image de production minimale ──
FROM python:3.12-slim-bookworm

WORKDIR /app

# Crée un utilisateur non-root (sécurité)
RUN useradd --create-home --shell /bin/bash appuser

# Copie uniquement le .venv depuis l'étape de build
COPY --from=uv --chown=appuser:appuser /app/.venv /app/.venv

# Ajoute le .venv au PATH
ENV PATH="/app/.venv/bin:$PATH"

# Affichage immédiat des logs
ENV PYTHONUNBUFFERED=1

# Transport HTTP pour Railway + Dust
ENV MCP_TRANSPORT=streamable-http

# Passe en utilisateur non-root
USER appuser

# Démarrage du serveur MCP
ENTRYPOINT ["dbt-mcp"]

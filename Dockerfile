# ── Étape 1 : Build de l'application ──
# Image Python 3.12 avec uv pré-installé (gestionnaire de packages rapide)
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS uv

# Dossier de travail dans le conteneur
WORKDIR /app

# Active la compilation bytecode Python (meilleures performances au démarrage)
ENV UV_COMPILE_BYTECODE=1

# Mode "copy" pour uv (évite des erreurs de liens symboliques)
ENV UV_LINK_MODE=copy

# Installe les dépendances (sans le projet lui-même, sans les dépendances de dev)
# CORRECTION : ajout de "id=uv-cache" pour compatibilité Railway
RUN --mount=type=cache,id=uv-cache,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    uv sync --frozen --no-install-project --no-dev --no-editable

# Copie tout le code source dans le conteneur
ADD . /app

# Simule un numéro de version (nécessaire car le dossier .git n'existe pas dans le build)
ARG SETUPTOOLS_SCM_PRETEND_VERSION=0.0.0
ENV SETUPTOOLS_SCM_PRETEND_VERSION=${SETUPTOOLS_SCM_PRETEND_VERSION}

# Installe le projet lui-même
# CORRECTION : ajout de "id=uv-cache" pour compatibilité Railway
RUN --mount=type=cache,id=uv-cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

# ── Étape 2 : Image minimale de production ──
FROM python:3.12-slim-bookworm

# Dossier de travail
WORKDIR /app

# Crée un utilisateur non-root pour la sécurité
RUN useradd --create-home --shell /bin/bash appuser

# Copie uniquement le .venv depuis l'étape de build (plus léger)
COPY --from=uv --chown=appuser:appuser /app/.venv /app/.venv

# Ajoute le .venv au PATH
ENV PATH="/app/.venv/bin:$PATH"

# Force l'affichage immédiat des logs (sans buffer)
ENV PYTHONUNBUFFERED=1

# ⭐ Transport HTTP pour Railway + Dust (remplace le "stdio" par défaut)
ENV MCP_TRANSPORT=streamable-http

# Passe en utilisateur non-root
USER appuser

# Commande de démarrage du serveur MCP
ENTRYPOINT ["dbt-mcp"]

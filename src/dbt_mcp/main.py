import asyncio
import os

from dbt_mcp.config.config import load_config
from dbt_mcp.config.transport import validate_transport
from dbt_mcp.mcp.server import create_dbt_mcp


def main() -> None:
    config = load_config()
    server = asyncio.run(create_dbt_mcp(config))
    transport = validate_transport(os.environ.get("MCP_TRANSPORT", "stdio"))

    if transport in ("sse", "streamable-http"):
        # Force l'écoute sur 0.0.0.0 (accessible depuis l'extérieur)
        server.settings.host = "0.0.0.0"
        server.settings.port = int(os.environ.get("PORT", 8000))
        # Désactive la protection DNS rebinding (bloque les hostnames externes par défaut)
        # Nécessaire pour que Railway et Dust puissent accéder au serveur
        server.settings.transport_security = None

    server.run(transport=transport)


if __name__ == "__main__":
    main()

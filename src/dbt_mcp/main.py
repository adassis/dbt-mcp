import asyncio
import os

from dbt_mcp.config.config import load_config
from dbt_mcp.config.transport import validate_transport
from dbt_mcp.mcp.server import create_dbt_mcp


def main() -> None:
    config = load_config()
    server = asyncio.run(create_dbt_mcp(config))
    transport = validate_transport(os.environ.get("MCP_TRANSPORT", "stdio"))

    # Pour les transports HTTP (Railway), on force l'écoute sur 0.0.0.0
    # car FastMCP écoute sur 127.0.0.1 par défaut (inaccessible depuis l'extérieur)
    # On patche directement l'objet settings interne du serveur
    if transport in ("sse", "streamable-http"):
        server._settings.host = "0.0.0.0"
        server._settings.port = int(os.environ.get("PORT", 8000))

    server.run(transport=transport)


if __name__ == "__main__":
    main()

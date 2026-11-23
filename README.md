# Lineage development server

Lineage II Interlude server based on aCis, with its datapack and a local Docker environment.

- `aCis_gameserver/`: Java server sources and configuration (JDK 21, Apache Ant).
- `aCis_datapack/`: HTML/XML content and SQL schema.
- `docker/`, `compose.yaml`: local MariaDB, LoginServer and GameServer.
- `compile.ps1`: build the server distribution into `dist/`.

Set `JAVA_HOME`, install Apache Ant and Docker Desktop, then run from PowerShell:

```powershell
.\docker\init-env.ps1
.\compile.ps1
docker compose up -d --build
```

Local client endpoints: `127.0.0.1:2106` and `127.0.0.1:7777`. Database credentials are generated in `.env`, which must remain untracked. The local `geodata/` directory must be supplied separately. Build outputs, logs, credentials, database volumes and editor runtimes are excluded from Git.

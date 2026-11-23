# Stackable scrolls and Life Stones

Copy system/etcitemgrp.dat into the Interlude client's system directory with the client closed. Keep a backup of the existing file. This table enables splitting stacks for 30 enchant scrolls and 40 Life Stones.

Rebuild using tools/client/patch_etcitemgrp.ps1 with -SystemDir and -ToolsDir (L2 File Editor data directory). The script verifies a byte-exact round trip and keeps a backup.

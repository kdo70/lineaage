# NPC dialog sizing patch

The server accepts `<!-- dialog-size: 800x600 -->` in a datapack HTML file or `NpcHtmlMessage.setWindowSize(800, 600)` in Java. See [the feature documentation](../../docs/npc-dialog-size.md).

The original client is supplied separately. This patch supports only the SHA256 recorded as `EXPECTED` in `patch_npc_dialog_size.py`; other DLL versions are rejected. Keep an original backup and close the client before installing a patched DLL.

```powershell
python -m pip install -r tools/client/requirements.txt
python tools/client/patch_npc_dialog_size.py <original-nwindow.dll> <patched-nwindow.dll>
$env:LINEAGE_NWINDOW_ORIGINAL = '<absolute-path-to-original-nwindow.dll>'
python tools/client/test_npc_dialog_size.py
```

Tests execute the native x86 patch in Unicorn with mocked engine resize/draw calls. They check sizing, header width, resets, invalid metadata, nine-slice coverage, texture bounds, stack balance and unchanged unrelated draws. The patched DLL was also checked in game; sizes, scrolling, reset and close were confirmed by the user.

Server checks, after compiling with Ant:

```powershell
java -cp "aCis_gameserver/build/classes;aCis_gameserver/lib/*" tools/client/CheckHtmlDialogSize.java
```

No proprietary client files, installed tool runtimes or credentials are included in this repository.

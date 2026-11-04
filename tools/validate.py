#!/usr/bin/env python3
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[1]
addon = root / 'GuildBountyForever'
toc = (addon / 'GuildBountyForever.toc').read_text().splitlines()
assert '## Interface: 16001' in toc
assert '## SavedVariables: GuildBountyForeverDB' in toc
files = [line.strip() for line in toc if line.strip() and not line.startswith('#')]
assert len(files) == len(set(files))
assert set(files) == {p.name for p in addon.glob('*.lua')}, 'Unlisted/stale runtime Lua files'
assert files.index('Identity.lua') < files.index('Models.lua')
assert files.index('Migration.lua') < files.index('Database.lua')
assert files[-1] == 'Bootstrap.lua'
ui = (addon / 'UI.lua').read_text()
assert 'ChatFrameUtil.InsertLink=function' not in ui
assert "hooksecurefunc(ChatFrameUtil,'InsertLink',capture)" in ui
assert 'C_CombatLogInternal' not in (addon / 'PvP.lua').read_text()
assert 'COMBAT_LOG_EVENT_INTERNAL_UNFILTERED' not in (addon / 'Bootstrap.lua').read_text()
for file in files:
    text = (addon / file).read_text()
    assert 'GetRealmName' not in text and 'Name-Realm' not in text, file
assert not list(addon.glob('*.xml')), 'Review XML when added'
with tempfile.TemporaryDirectory(prefix='gbf-check-') as tmp:
    for file in files:
        path = addon / file
        assert path.is_file(), file
        subprocess.run(['luajit', '-b', str(path), tmp + '/check.luac'], check=True)
        subprocess.run(['luac', '-p', str(path)], check=True)
print(f'PASS: TOC, SavedVariables, {len(files)} referenced files, LuaJIT 5.1 and Lua 5.4 syntax.', flush=True)
subprocess.run(['luajit', str(root / 'tests' / 'run.lua')], cwd=root, check=True)
subprocess.run(['luajit', str(root / 'tests' / 'mail.lua')], cwd=root, check=True)
for scenario in ['init-failure', 'hook-failure', 'healthy']:
    subprocess.run(['luajit', str(root / 'tests' / 'ui.lua'), scenario], cwd=root, check=True)
print('All terminal checks passed. In-game rendering and multiplayer checks remain.')

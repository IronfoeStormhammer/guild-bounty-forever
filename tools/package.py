#!/usr/bin/env python3
"""Build an installable ZIP with exactly one addon directory."""
from pathlib import Path
import hashlib
import zipfile
root = Path(__file__).resolve().parents[1]
addon = root / 'GuildBountyForever'
version = next(line.split(':', 1)[1].strip() for line in (addon / 'GuildBountyForever.toc').read_text().splitlines() if line.startswith('## Version:'))
output = root / 'dist'
output.mkdir(exist_ok=True)
archive = output / f'GuildBountyForever-{version}.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
    for path in sorted(addon.rglob('*')):
        if path.is_file():
            z.write(path, path.relative_to(root))
print(archive)
print('SHA256:', hashlib.sha256(archive.read_bytes()).hexdigest())

#!/usr/bin/env python3
"""Install only this addon; stage first, preserve a previous installation."""
from pathlib import Path
from datetime import datetime
import hashlib
import shutil
import tempfile
import argparse
source = Path(__file__).resolve().parents[1] / 'GuildBountyForever'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--addons-dir', required=True, type=Path, help='Forever Interface/AddOns directory')
args = parser.parse_args()
addons = args.addons_dir.expanduser().resolve()
client = addons.parent.parent
assert addons.is_dir(), 'Requested Forever AddOns directory does not exist'
destination = addons / source.name
stage_parent = Path(tempfile.mkdtemp(prefix='.gbf-stage-', dir=addons))
stage = stage_parent / source.name
try:
    shutil.copytree(source, stage)
    for p in source.rglob('*'):
        if p.is_file():
            assert hashlib.sha256(p.read_bytes()).digest() == hashlib.sha256((stage / p.relative_to(source)).read_bytes()).digest()
    if destination.exists():
        backups = client / 'GuildBountyForever-backups'
        backups.mkdir(exist_ok=True)
        backup = backups / datetime.now().strftime('%Y%m%d-%H%M%S-%f')
        destination.rename(backup)
        print('Previous addon preserved at:', backup)
    stage.rename(destination)
finally:
    shutil.rmtree(stage_parent)
print('Installed and verified:', destination)

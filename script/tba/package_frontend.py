"""Validate Vite/SDK output and package only compiled frontend files."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tarfile


def main():
    root = Path(__file__).resolve().parents[2]
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root).decode().strip()
    expected_revision = os.environ.get('GITHUB_SHA', revision)
    if not re.fullmatch(r'[a-f0-9]{40}', revision) or revision != expected_revision:
        raise RuntimeError('Checkout does not match workflow revision')
    vite = root / 'public/vite'
    manifest_path = vite / '.vite/manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    if not manifest or not any(key.endswith('dashboard.js') for key in manifest):
        raise RuntimeError('Dashboard entry missing from Vite manifest')
    for entry in manifest.values():
        for name in [entry.get('file')] + entry.get('css', []) + entry.get('assets', []):
            if name:
                path = (vite / name).resolve()
                if not path.is_relative_to(vite.resolve()) or not path.is_file():
                    raise RuntimeError('Missing or unsafe Vite output: ' + name)
        for key in entry.get('imports', []) + entry.get('dynamicImports', []):
            if key not in manifest:
                raise RuntimeError('Missing manifest import: ' + key)
    sdk_files = [root / 'public/packs/js' / ('sdk.js' + ext) for ext in ('', '.gz', '.br')]
    for path in sdk_files:
        if not path.is_file() or path.stat().st_size == 0:
            raise RuntimeError('SDK output missing: ' + str(path))
    output = root / 'dist'
    output.mkdir(exist_ok=True)
    metadata = output / 'build.json'
    metadata.write_text(json.dumps({
        'commit': revision, 'run_id': os.environ.get('GITHUB_RUN_ID'),
        'repository': os.environ.get('GITHUB_REPOSITORY'),
        'scope': 'Vite frontend and SDK only; no Rails assets, sources, secrets, DB or migrations',
    }, indent=2) + '\n', encoding='utf-8')
    archive = output / ('tba-frontend-' + revision + '.tar.gz')
    with tarfile.open(archive, 'x:gz') as bundle:
        for path in sorted(vite.rglob('*')):
            if path.is_symlink():
                raise RuntimeError('Symlink not allowed in build output: ' + str(path))
            if path.is_file():
                bundle.add(path, arcname=path.relative_to(root).as_posix(), recursive=False)
        for path in sdk_files:
            bundle.add(path, arcname=path.relative_to(root).as_posix(), recursive=False)
        bundle.add(metadata, arcname='build.json', recursive=False)
    with archive.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    archive.with_suffix('.gz.sha256').write_text(digest + '  ' + archive.name + '\n', encoding='ascii')
    print('Compiled frontend package:', archive.name)
    print('Bytes:', archive.stat().st_size)
    print('SHA-256:', digest)


if __name__ == '__main__':
    main()

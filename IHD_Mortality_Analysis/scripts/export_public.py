"""Build a standalone GitHub upload ZIP using an explicit public-file allowlist.

Run from any directory: python scripts/export_public.py
The course originals, local R binaries, Git history and earlier report snapshot
are never included. The frozen analysis CSV is included with its provenance notes.
"""
from pathlib import Path
import re
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PUBLIC_FILES = [
    'README.md', 'DATA_PROVENANCE.md', 'PUBLICATION_CHECKLIST.md',
    'GITHUB_SETUP.md', '.gitignore', 'Code_public.Rmd', 'Report_public.html',
    'validation_results.json', 'endpoint_summary.csv', 'R_RENDER_VALIDATION.txt',
    'hcd_sdr_filtered.csv',
    'figures/overall-trend.png', 'figures/sex-trends.png',
    'figures/endpoint-comparison.png', 'figures/sex-gap.png', 'figures/age-band-rates.png',
    'scripts/install_dependencies.R', 'scripts/render.R', 'scripts/prepare_data.R',
    'scripts/validate_data.py', 'scripts/export_public.py',
]

def main():
    for name in PUBLIC_FILES:
        assert (ROOT / name).is_file(), f'Missing public file: {name}'
    # Check project-relative Markdown links before copying into a new repository.
    for name in PUBLIC_FILES:
        if name.endswith('.md'):
            text = (ROOT / name).read_text(encoding='utf-8')
            for link in re.findall(r'\]\(([^)]+)\)', text):
                if '://' not in link and not link.startswith('#'):
                    target = (Path(name).parent / link.split('#')[0]).as_posix()
                    assert target in PUBLIC_FILES, f'Unpackaged link in {name}: {target}'
    destination = ROOT / 'github-release'
    destination.mkdir(exist_ok=True)
    project = destination / 'ihd-mortality-four-country-analysis'
    project.mkdir(exist_ok=True)
    for name in PUBLIC_FILES:
        target = project / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / name, target)
    archive = destination / 'ihd-mortality-four-country-analysis.zip'
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED) as out:
        for name in PUBLIC_FILES:
            out.write(ROOT / name, name)
    with zipfile.ZipFile(archive) as check:
        assert check.namelist() == PUBLIC_FILES
        assert check.testzip() is None
    (destination / 'PUBLIC_FILES.txt').write_text('\n'.join(PUBLIC_FILES)+'\n', encoding='utf-8')
    print(f'Created folder {project.name} and ZIP: {len(PUBLIC_FILES)} files; relative links and ZIP integrity checked.')

if __name__ == '__main__':
    main()

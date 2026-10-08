"""Run the exact Foundation/Combine language and state model on macOS without an iOS SDK.
This validates models only; it does not compile SwiftUI views or replace iOS UI tests.
"""
from pathlib import Path
import shutil, subprocess, tempfile
ROOT=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='lifeguide-checks-') as temp:
    work=Path(temp)
    bundle=work/'LanguageChecks.app/Contents'
    binary=bundle/'MacOS/LanguageChecks';binary.parent.mkdir(parents=True)
    resources=bundle/'Resources';resources.mkdir()
    for path in (ROOT/'LifeGuide/Resources').iterdir():
        if path.suffix=='.json': shutil.copyfile(path,resources/path.name)
        elif path.suffix=='.lproj': shutil.copytree(path,resources/path.name)
    model=(ROOT/'LifeGuide/Models.swift').read_text().split('\nenum Theme')[0]
    model=model.replace('import SwiftUI','import Foundation\nimport Combine').replace('import WidgetKit', '')
    (work/'Models.swift').write_text(model)
    subprocess.run(['swiftc','-module-cache-path',str(work/'cache'),str(work/'Models.swift'),str(ROOT/'LifeGuide/Localization.swift'),str(ROOT/'LifeGuide/GuideContent.swift'),str(ROOT/'LifeGuide/DailyReading.swift'),str(ROOT/'tests/LanguageStateChecks.swift'),'-o',str(binary)],check=True)
    subprocess.run([str(binary)],check=True)

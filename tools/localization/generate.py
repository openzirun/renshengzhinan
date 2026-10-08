"""Generate native .strings resources; reject missing translations or format mismatches."""
from pathlib import Path
import csv,re,json
ROOT=Path(__file__).resolve().parents[2]
rows=list(csv.reader((Path(__file__).parent/'ui.tsv').open(),delimiter='|'))
header=rows[0];data={code:{} for code in header[1:]}
for row in rows[1:]:
    assert len(row)==len(header),(row[0],len(row))
    key=row[0]
    formats=re.findall(r'%(?:ld|@)',row[1])
    for code,value in zip(header[1:],row[1:]):
        assert value and key not in data[code],(code,key)
        assert re.findall(r'%(?:ld|@)',value)==formats,(code,key)
        data[code][key]=value.replace('\\n','\n')
for code,values in data.items():
    dest=ROOT/'LifeGuide/Resources'/f'{code}.lproj';dest.mkdir(parents=True,exist_ok=True)
    (dest/'UI.strings').write_text('\n'.join(f'{json.dumps(k,ensure_ascii=False)} = {json.dumps(v,ensure_ascii=False)};' for k,v in values.items())+'\n')
    (dest/'InfoPlist.strings').write_text('"CFBundleDisplayName" = '+json.dumps(values['appName'],ensure_ascii=False)+';\n')
used=set()
for f in (ROOT/'LifeGuide').glob('*.swift'):
    used.update(re.findall(r'text\("([a-zA-Z]+)"',f.read_text()))
used.update(['pdfHint','translationHint'])
assert not used-data['en'].keys(),used-data['en'].keys()
print('Validated',len(data),'languages;',len(data['en']),'UI strings each; matching format arguments.')

"""Import pinned, downloaded community Markdown without executing upstream code.
Usage: python3 tools/import_translations.py MULTILINGUAL_ROOT VIETNAMESE_ROOT
Download the two pinned tarballs documented in CONTENT_SOURCES.md first.
"""
from pathlib import Path
import sys, re, json, hashlib, shutil
from urllib.parse import quote
ROOT=Path(__file__).resolve().parents[1]
MULTI_SHA='d67d7b3277c911eab9d422b4390e7611251003a9'
VI_SHA='4a57509c0312a77e6ec7c8ac363bed4909edf267'
LABELS={
'en':['Cost','In plain terms','Benefit','Evidence grade','Sources','Notes'],
'ru':['Стоимость','Простыми словами','Эффект','Уровень доказательности','Источники','Примечания'],
'es':['Costo','En términos sencillos','Beneficio','Nivel de evidencia','Fuentes','Notas'],
'pt':['Custo','Em linguagem simples','Benefício','Nível de evidência','Fontes','Notas'],
'ar':['التكلفة','بعبارة بسيطة','الفائدة','مستوى الدليل','المصادر','ملاحظات'],
'id':['Biaya','Singkatnya','Manfaat','Tingkat bukti','Sumber','Catatan'],
'vi':['Chi phí','Nói dễ hiểu','Lợi ích','Mức chứng cứ','Nguồn','Ghi chú']}
EXPECTED={'en':665,'ru':665,'es':665,'pt':665,'ar':635,'id':630,'vi':641}
KEYS=['cost','summary','benefit','evidence','sources','notes']
def plain(text):
    text=re.sub(r'<!--.*?-->','',text,flags=re.S)
    # Strip emphasis only; retain links and all quotations, numbers and qualifications.
    return text.replace('**','').strip()

def main():
    manifest=[]
    for lang,labels in LABELS.items():
        root=Path(sys.argv[2] if lang=='vi' else sys.argv[1])
        folder=root/'book' if lang=='vi' else root/'book'/lang
        repo='chuanman2707/HowToLiveBetter' if lang=='vi' else 'dlgrv/HowToLiveBetter'
        sha=VI_SHA if lang=='vi' else MULTI_SHA
        chapters=[]; articles=[]; files=[]; anomalies=[]
        for file in sorted(folder.glob('*.md')):
            raw=file.read_text()
            chapter_id=int(file.name.split('-')[0])
            heading=re.search(r'^#\s+(?:\d+\.\s*)?(.+)',raw,re.M)
            matches=list(re.finditer(r'^###\s+(\d+)\.\s+(.+)$',raw,re.M))
            assert heading and matches, file
            relative=file.relative_to(root).as_posix()
            url=f'https://github.com/{repo}/blob/{sha}/{quote(relative)}'
            chapters.append(dict(id=chapter_id,title=heading[1],intro=plain(raw[heading.end():matches[0].start()]),page=0))
            seen_numbers={}; last_number=0
            for i,m in enumerate(matches):
                number=int(m[1])
                seen_numbers[number]=seen_numbers.get(number,0)+1
                if number<=last_number: anomalies.append(dict(file=relative,position=i+1,printedNumber=number))
                last_number=number
                article_id=f'{chapter_id}-{number}' + (f'-duplicate-{seen_numbers[number]}' if seen_numbers[number]>1 else '')
                body=raw[m.end():matches[i+1].start() if i+1<len(matches) else len(raw)]
                # Chapter license/footer belongs to source file, not the final article's notes.
                body=re.split(r'^##?\s+',body,flags=re.M)[0]
                pattern=r'^- ('+'|'.join(re.escape(x) for x in labels)+r')\s*[:：]\s*'
                fields=list(re.finditer(pattern,body,re.M)); assert len(fields)==6,(file,number,len(fields))
                values={KEYS[labels.index(f[1])]:plain(body[f.end():fields[j+1].start() if j+1<len(fields) else len(body)]) for j,f in enumerate(fields)}
                assert all(values.values()),(file,number)
                assert re.match(r'[ABCأ]',values['evidence']),(file,number,values['evidence'])
                articles.append(dict(id=article_id,chapterID=chapter_id,number=number,title=plain(m[2]),page=0,sourceURL=url,**values))
            files.append(dict(path=relative,sha256=hashlib.sha256(file.read_bytes()).hexdigest()))
            dest=ROOT/'ContentSources'/lang/file.name
            dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(file,dest)
        assert len(chapters)==34,(lang,len(chapters))
        assert len(articles)==EXPECTED[lang],(lang,len(articles))
        assert len(set(a['id'] for a in articles))==len(articles)
        for license_file in ['LICENSE','README.md']:
            if (root/license_file).exists(): shutil.copyfile(root/license_file,ROOT/'ContentSources'/lang/license_file)
        data=dict(version=sha[:12],sourceURL=f'https://github.com/{repo}',chapters=chapters,articles=articles,extras=[])
        (ROOT/f'LifeGuide/Resources/guide-{lang}.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
        manifest.append(dict(language=lang,repository=repo,commit=sha,articles=len(articles),chapters=len(chapters),files=files,numberingAnomalies=anomalies))
        print(lang,len(chapters),len(articles))
    (ROOT/'ContentSources/manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
if __name__=='__main__': main()

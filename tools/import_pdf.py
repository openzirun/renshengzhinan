"""Import the supplied edition using PDF bookmarks, not guessed heading patterns.
Requires pypdf. Usage: python3 tools/import_pdf.py /path/to/HowToLiveBetter.pdf
"""
import sys, re, json, hashlib, shutil, bisect
from pathlib import Path
from pypdf import PdfReader
root = Path(__file__).resolve().parents[1]
source = Path(sys.argv[1])
reader = PdfReader(source)
pages = []
for page in reader.pages:
    lines = page.extract_text().splitlines()
    pages.append('\n'.join(l for l in lines if not l.startswith('高性价比人生指南 ') and not re.fullmatch(r'\d+ / \d+', l.strip())))
offsets=[]
text=''
for page in pages:
    offsets.append(len(text)); text += page+'\n'
# Match bookmark titles even when the PDF wraps a heading across two lines.
compact=[]; positions=[]
for i,c in enumerate(text):
    if not c.isspace(): compact.append(c); positions.append(i)
compact=''.join(compact)
def locate(bookmark):
    page=reader.get_destination_page_number(bookmark)
    start=bisect.bisect_left(positions, offsets[page])
    needle=re.sub(r'\s','',bookmark['/Title'])
    at=compact.find(needle,start)
    assert at>=0, bookmark['/Title']
    assert page + 1 == len(pages) or positions[at] < offsets[page + 1], bookmark['/Title']
    return positions[at], positions[at+len(needle)-1]+1, page+1

def flow(s):
    # Retain bullets/paragraphs; remove typesetter line wraps, keeping Latin word spaces.
    lines=s.strip().splitlines(); out=''
    for line in lines:
        line=line.strip()
        if not line: continue
        if not out: out=line; continue
        if line.startswith(('•','‣')) or re.match(r'^\d+\. ',line): out+='\n'+line
        elif re.search(r'[\u4e00-\u9fff，。；：）]$',out) or re.match(r'^[\u4e00-\u9fff，。；：）]',line): out+=line
        else: out+=' '+line
    return out
outline=reader.outline
chapters=[]; articles=[]; extras=[]
for i,b in enumerate(outline):
    if isinstance(b,list): continue
    start,end,page=locate(b)
    following=next((x for x in outline[i+1:] if not isinstance(x,list)),None)
    stop=locate(following)[0] if following else len(text)
    match=re.match(r'^(\d+)\. (.+)',b['/Title'])
    if not match:
        extras.append(dict(id=f'extra-{len(extras)}',title=b['/Title'],body=flow(text[end:stop]),page=page))
        continue
    number=int(match[1]); children=outline[i+1] if i+1<len(outline) and isinstance(outline[i+1],list) else []
    children=[x for x in children if not isinstance(x,list) and re.match(r'^\d+\. ', x['/Title'])]
    chapters.append(dict(id=number,title=match[2],intro=flow(text[end:locate(children[0])[0]]),page=page))
    for j,item in enumerate(children):
        a,z,p=locate(item)
        stop_item=locate(children[j+1])[0] if j+1<len(children) else stop
        body=text[z:stop_item].strip()
        fields={}
        parts=re.split(r'•\s*(成本|说人话|收益|证据等级|来源|备注)：',body)
        for k in range(1,len(parts),2): fields[parts[k]]=flow(parts[k+1])
        n,title=item['/Title'].split('. ',1)
        assert all(fields.get(k) for k in ['成本','说人话','收益','证据等级','来源']), (number,n,fields.keys())
        articles.append(dict(id=f'{number}-{n}',chapterID=number,number=int(n),title=title,page=p,cost=fields['成本'],summary=fields['说人话'],benefit=fields['收益'],evidence=fields['证据等级'].strip(),sources=fields['来源'],notes=fields.get('备注','')))
assert len(chapters)==34
assert len(articles)==672, len(articles)
assert len(set(a['id'] for a in articles))==672
for c in chapters:
    nums=[a['number'] for a in articles if a['chapterID']==c['id']]
    assert nums==list(range(1,len(nums)+1)), c
assert all(re.fullmatch(r'[ABC](（.*）)?', a['evidence']) for a in articles)
data=dict(version='2026-10-08 · 0cec2b3',sourceURL='https://github.com/eternity4719/HowToLiveBetter',sha256=hashlib.sha256(source.read_bytes()).hexdigest(),chapters=chapters,articles=articles,extras=extras)
resources=root/'LifeGuide/Resources'; resources.mkdir(parents=True,exist_ok=True)
(resources/'guide.json').write_text(json.dumps(data,ensure_ascii=False,indent=2))
shutil.copyfile(source,resources/'HowToLiveBetter.pdf')
print(f'Validated {len(chapters)} chapters, {len(articles)} complete articles, {len(extras)} supplementary sections; {len(reader.pages)} PDF pages.')

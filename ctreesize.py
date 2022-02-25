#!/usr/bin/python3

import sys,os,stat

def getsize(fn,dev):
    st=os.stat(fn,follow_symlinks=False)
    if st.st_dev!=dev: return 'm',0
    if stat.S_ISDIR(st.st_mode) and not stat.S_ISLNK(st.st_mode):
        fns=getfns(fn)
        return 'd',st.st_blocks*512+sum(si for typ,si in fns.values())
    typ='?'
    if stat.S_ISLNK(st.st_mode): typ='l'
    if stat.S_ISREG(st.st_mode): typ=' '
    return typ,st.st_blocks*512

def getfns(dn):
    if not dn in dns:
        dev=os.stat(dn).st_dev
        dns[dn]={
            fn:getsize(fn,dev)
            for fn in map(lambda fn:os.path.join(dn,fn),os.listdir(dn))
        }
    return dns[dn]

def prcfmt(v):
    v*=100
    fmt='%.0f'
    if v<20: fmt='%.1f'
    if v<5: fmt='%.2f'
    return (fmt%v)+'%'

def sifmt(v):
    ext=[' ','k','M','G','T']
    while v>1024 and len(ext)>2: v/=1024; ext=ext[1:]
    fmt='%.0f'
    if v<20: fmt='%.1f'
    if v<5: fmt='%.2f'
    return (fmt%v)+ext[0]

def prtfns(dn):
    fns=getfns(dn)
    print(f'##### {dn} #####')
    print(f'  0:    --    -- d ..')
    sisum=sum(si for typ,si in fns.values())
    ret=[]
    for i,(fn,(typ,si)) in enumerate(sorted(fns.items(),key=lambda v:-v[1][1])):
        if i==20: print(' [..] '); break
        if typ=='d': ret.append(fn)
        print((f'{len(ret):3d}:' if typ=='d' else ' '*4)+f' {prcfmt(si/sisum):>5s} {sifmt(si):>5s} {typ} {os.path.basename(fn)}')
    print(' '*(4+1+5+1)+f'{sifmt(sisum):5>s}   Sum')
    return ret


dn='.'
if len(sys.argv)>1: dn=sys.argv[1]
dn=os.path.realpath('.')

dns={}

while True:
    fns=prtfns(dn)
    print('Input folder ID/name (""->remain, r->refresh, q->quit)')
    inp=sys.stdin.readline().strip()
    if inp=='q': break
    elif inp=='r': dns={}
    elif inp.isdigit() and 0<=int(inp)<=len(fns):
        inp=int(inp)
        if inp==0: dn=os.path.dirname(dn)
        else: dn=fns[inp-1]
    elif inp=='..': dn=os.path.dirname(dn)
    else:
        fns=[fn for fn in fns if os.path.basename(fn)==inp]
        if len(fns)!=1: print('Error: unkown dir')
        else: dn=fns[0]


# Usage (from mythical-sanctuary/): python3 tools/render_world_map.py  — keep in sync with src/server/World/TerrainBuilder.lua
# Python port of TerrainBuilder.HeightAt (Perlin noise approximated) -> top-down render
import math, numpy as np, random
from PIL import Image, ImageDraw
random.seed(1)
P=list(range(256)); random.shuffle(P); P+=P
def fade(t): return t*t*t*(t*(t*6-15)+10)
def grad(h,x,y,z):
    h&=15; u=x if h<8 else y; v=y if h<4 else (x if h in(12,14) else z)
    return (u if h&1==0 else -u)+(v if h&2==0 else -v)
def noise(x,y,z=0.0):
    X,Y,Z=int(math.floor(x))&255,int(math.floor(y))&255,int(math.floor(z))&255
    x-=math.floor(x);y-=math.floor(y);z-=math.floor(z)
    u,v,w=fade(x),fade(y),fade(z)
    A=P[X]+Y;AA=P[A]+Z;AB=P[A+1]+Z;B=P[X+1]+Y;BA=P[B]+Z;BB=P[B+1]+Z
    L=lambda a,b,t:a+t*(b-a)
    return L(L(L(grad(P[AA],x,y,z),grad(P[BA],x-1,y,z),u),L(grad(P[AB],x,y-1,z),grad(P[BB],x-1,y-1,z),u),v),
             L(L(grad(P[AA+1],x,y,z-1),grad(P[BA+1],x-1,y,z-1),u),L(grad(P[AB+1],x,y-1,z-1),grad(P[BB+1],x-1,y-1,z-1),u),v),w)
def ss(e0,e1,x):
    t=min(max((x-e0)/(e1-e0),0),1); return t*t*(3-2*t)
lerp=lambda a,b,t:a+(b-a)*t
MINX,MAXX,MINZ,MAXZ=-640,640,-1080,360; RIM_H,RIM_W,BASE=150,140,20
river=[((150,-905),46),((175,-760),40),((135,-560),33),((165,-360),27),((140,-180),22),((132,0),19),((95,180),16),((40,350),14)]
paths=[(12,[(0,120),(0,0),(0,-150)]),(8,[(-90,20),(0,0),(100,-5)]),(9,[(100,-5),(160,4),(230,10)]),(9,[(0,-150),(-30,-300),(-60,-440),(-90,-515)]),
 (7,[(-60,-440),(60,-520),(180,-620),(230,-655)]),(7,[(-90,-600),(-20,-720),(80,-830),(125,-860)]),(4,[(-30,-300),(-160,-360),(-290,-420)])]
feats=[("Clearing",(-90,-560),55,30),("Mound",(235,-660),70,14),("Hill",(-345,-440),110,55),("Cliff",(150,-960),130,70),("Clearing",(95,-810),45,44)]
def pdist(pts,x,z):
    best,bi,bt=1e9,0,0
    for i in range(len(pts)-1):
        (ax,az),(bx,bz)=pts[i],pts[i+1]; abx,abz=bx-ax,bz-az; l2=abx*abx+abz*abz
        t=min(max(((x-ax)*abx+(z-az)*abz)/l2,0),1) if l2>0 else 0
        d=math.hypot(x-(ax+abx*t),z-(az+abz*t))
        if d<best: best,bi,bt=d,i,t
    return best,bi,bt
def riverAt(x,z):
    w=noise(x/60,z/60,7.3)*9
    d,i,t=pdist([p for p,_ in river],x+w,z); return d,lerp(river[i][1],river[i+1][1],t)
def pathAt(x,z):
    return min(pdist(pts,x,z)[0]-w/2 for w,pts in paths)
def H(x,z):
    h=BASE+noise(x/260,z/260,0.3)*18+noise(x/95,z/95,1.7)*7+noise(x/28,z/28,3.1)*1.6
    e=min(x-MINX,MAXX-x,z-MINZ,MAXZ-z)
    if e<RIM_W: t=1-e/RIM_W; h+=(t**2.2)*RIM_H*(0.75+0.35*noise(x/80,z/80,9.1))
    vd=math.hypot(x,z); fo=ss(170*1.1,170*2.2,vd)
    if fo>0:
        ridge=1-abs(noise(x/170,z/170,12.5))
        valley=ss(6,34,pathAt(x,z))*ss(26,26*3.5,riverAt(x,z)[0])
        h+=(ridge**2.2)*34*fo*valley+noise(x/55,z/55,14.2)*5*fo
    for k,(cx,cz),r,fh in feats:
        d=math.hypot(x-cx,z-cz)
        if d<r*1.4:
            w=1-ss(r*0.55,r*1.4,d)
            if k=="Clearing": h=lerp(h,fh+noise(x/18,z/18)*0.8,w)
            elif k=="Mound": h+=fh*w
            elif k=="Hill": cone=ss(0,1,1-d/(r*1.4)); h+=fh*(cone**1.3)*(0.85+0.25*noise(x/40,z/40,4.4))
            elif k=="Cliff": h+=fh*ss(0,1,w*1.6)
    dv=math.hypot(x,z)
    if dv<170*1.5: w=1-ss(170*0.75,170*1.5,dv); h=lerp(h,26+noise(x/40,z/40,5.5)*1.4,w)
    pe=pathAt(x,z)
    if pe<6: w=1-ss(-2,6,pe); h=lerp(h,BASE+(h-BASE)*0.92,w)
    rd,lv=riverAt(x,z); half=13
    if rd<half*2.6:
        bank=lv+1.5
        if rd<half: h=min(h,lv-3-(1-rd/half)*5)
        else: w=1-ss(half,half*2.6,rd); h=lerp(h,max(bank,min(h,bank+(rd-half)*0.45)),w)
    return h,rd,lv,pe
S=4; W=(MAXX-MINX)//S; D=(MAXZ-MINZ)//S
img=np.zeros((D,W,3),np.uint8); hs=np.zeros((D,W))
for j in range(D):
    for i in range(W):
        x=MINX+i*S; z=MINZ+j*S; h,rd,lv,pe=H(x,z); hs[j,i]=h
        if h<lv and rd<26*1.4: c=(60,120,150)
        elif pe<0: c=(150,140,124) if math.hypot(x,z)<200 else (120,96,70)
        elif h>95: c=(110,108,104)
        elif math.hypot(x,z)<170: c=(118,160,80)
        else: c=(72,118,62)
        img[j,i]=c
# hillshade
gx=np.gradient(hs,axis=1); gz=np.gradient(hs,axis=0)
shade=np.clip(1-0.18*(gx+gz),0.45,1.4)
img=np.clip(img*shade[...,None],0,255).astype(np.uint8)
im=Image.fromarray(img).resize((W*2,D*2)); dr=ImageDraw.Draw(im)
lm={"ClockTower":(0,0),"Bridge":(132,2),"NorthGate":(0,-150),"SanctuaryGate":(-30,72),"ElderTree":(-90,-560),"Temple":(238,-662),"Waterfall":(150,-912),"Cave":(-298,-424),"Shrine":(95,-810)}
for n,(x,z) in lm.items():
    px,pz=(x-MINX)/S*2,(z-MINZ)/S*2; dr.ellipse([px-5,pz-5,px+5,pz+5],fill=(255,210,90)); dr.text((px+7,pz-6),n,fill=(255,255,255))
im.save('docs/world_map_preview.png')
print("height range",hs.min(),hs.max(), "village mean", hs[(0-MINZ)//S-5:(0-MINZ)//S+5,(0-MINX)//S-5:(0-MINX)//S+5].mean())

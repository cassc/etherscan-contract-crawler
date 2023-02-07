//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './Utils.sol';

function renderResponsiveAnimation(uint256 tokenId, uint8 appearance)
    pure
    returns (string memory)
{
    return
        string.concat(
            "<!DOCTYPE html><html><style>html,body{height:100%;width:100%;padding:0;margin:0;overflow:hidden;}svg{display: block;}</style><body><svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='100%' height='100%' viewPort='0 0 100% 100%' id='a",
            utils.uint2str(appearance),
            "'><svg id='c'/><style>#a0,#a1{--fill:black;background:linear-gradient(#b9b6d0,#ffffff);display:flex;align-items:center;justify-content:center;}@keyframes s{0%{opacity:1;}100%{opacity:0;}}#a2{--fill:white;background:#202124;}#a1{background:#eee !important;}@media (prefers-color-scheme:dark){#a0{--fill:white;background:linear-gradient(#2d2a2a,#2b2f71);}}</style><script>//<![CDATA[ \n",
            'let token=',
            utils.uint2str(tokenId),
            ",ns='http://www.w3.org/2000/svg',r=Math.random,rou=Math.round,ce=(...e)=>document.createElementNS(...e),a=(e,...t)=>e.setAttribute(...t),de=document.documentElement,vp=[de.clientWidth,de.clientHeight];const same=token%2==1;function cS(e,t){let n=5*r()+.2,$=ce(ns,'svg'),l=ce(ns,'circle');a(l,'cx',20),a(l,'cy',20),a(l,'r',20),a(l,'fill','transparent'),$.appendChild(l),a($,'x',e+10),a($,'y',t+10),document.getElementById('c').appendChild($);let i=[],o=same?8:20*r()+1,d=same?2:1.5*r()+.5,p=same?'round':r()>.5?'butt':r()>.5?'round':'square',m=20+d/2,c=same?12:(12*r()<<0)+4,u=360/c;for(let f=0;f<c;f++){let _=ce(ns,'line');$.appendChild(_),a(_,'x1',0),a(_,'y1',m),a(_,'x2',o),a(_,'y2',m),a(_,'stroke-width',d),a(_,'stroke-linecap',p),a(_,'stroke','var(--fill)'),a(_,'transform',`rotate(${f*u} 20 ${m})`),i.push(_)}spd(i,n,c);let v,g=(...e)=>$.addEventListener(...e);function E(){spd(i,.2-r()/100,c),v&&clearTimeout(v),v=setTimeout(()=>spd(i,n,c),5e3)}g('mouseover',E),g('mouseout',E),g('mousemove',E),g('mouseup',E),g('mousedown',()=>spd(i,1e6))}function spd(e,t,n){let $=t/n;for(let l=0;l<e.length;l++){let i=e[l].style;i.animation=`s ${t}s linear infinite`,i.animationDelay=`${-(t-$)+l*$}s`}}let s=Math.min(...vp),margin=Math.min(Math.max(s/10,20),120),sp=70,[w,h]=vp,cl=rou((w-2*margin)/sp),rw=rou((h-2*margin)/sp);if(h<=500&&w<h)rw=cl;for(let x=0;x<cl;x++)for(let y=0;y<rw;y++)cS(x*sp+(w-cl*sp)/2,y*sp+(h-rw*sp)/2);window.addEventListener('resize',()=>location.href=location.href);//]]></script></svg></body></html>"
        );
}
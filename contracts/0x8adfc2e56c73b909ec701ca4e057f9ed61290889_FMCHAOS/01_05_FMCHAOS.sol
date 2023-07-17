// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: feel my chaos
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    mr|wTxmKB$WdMZIG})zXyPKdGz;|Vxv|<vr~<*)r):<^=xu)xxxr^<*!^=rvv|LY)xi}uYViY}i)rc}vYv|YTVLVXulykXXkIscuckzVlT}}vcwXwzVkycczXYVcVlcVVYLTllLTVV}lcuTzmOMwyy    //
//    d^,|zY##@BgggORZVulVkwlWKzVsk|rrxuvVV)".-,<xv<~)v)^^)!:-:_*x*rvv^xr^v^**_=!!^"-=YVLT=x*krrVTwVlY<*)vvkXcyzzwkzIzkXzmzXzkViTXwTVyuLYcTTiLuTTY}kclwkTL}V    //
//    T^~!|lQ##BbRDRO3cTVl}ixVw}))v*vylV)^Y^_-_:xx)~:"!|T}Lvilv_~!_:;)==~rxv*=.```-``-=*^vvl^k)}}LcyyYv*rYiVkTx}yywXIskIVc|xlIcVVywlTVc}iLTLiiuY}LLTiuuPxxLk    //
//    ~=:)x|$QQOOZDDMwi)VyTXwTc*=i)uriV9mLyv<^)*l^!-__-.xr^:~v^,;:__"=^--"=L)!v))rv!_ '^vcuz|wwzywwylcxLxv}TV}VlkucyyyksVkVVzzwkzwuY}l}TuYYV}Lyu}xVzYvylxvxV    //
//    =;^|yID9OmMGX3zyKxzVvc*Y}uiYlGx|xvLyWrxzTVVvTr":=_**::;)|Y*^<r<=:,:)uY}ir!=:|r_`.,*r)rx::lxxuiluV}uLYuTxTcluVykkVuvwXXsywxIkswVVcTVkzkVyIVu}TkclzyxixV    //
//    x!=rVwgBgGOs9yPlKmku}WcV))r^v)rx^)<TVi*xXL}r)u^kux*x;^)**rxu;<;x="_"*))Tr<uxVyuLvx)v^rxYvxlcLx}lyLXTVL}yyyIwXKXPI3sKiIO$B##VV)xurxxc}uulXwVlVuLTmyxx}y    //
//    IQdxvYIOBMmDzukzkmYxrwY)L*~;)=|l)^!*i)^!<}xvTccKG3X3VTkvur)x~i*=~*=!^^uTXwV}zTVv}Tvuxr*Vxrv:!*r}}xy*iuuVPmXwuIW0$QQB#@@@@@#Y)l~)X}lluzyT}TVyyVlVMwYVuu    //
//    ,xLvcxVGP0MK3sGKluxczTv=*^;~)~;;<rx}}x:^)Vi|ixx)LXWVwYVxwxvr*xLVwuxuyT)r)T^;)Vwz}wx;i):xvvYxuLzVsMOdO98QBB##@@@@@@@@@@@@@@0VwyTwmkykkmzXwlVlVcTwXIyzVi    //
//    rkxrxx|YwwszIzGsyLlxvrPd$W3WZmXKmMWW$gMPgZWsGMWdGWMMZdPsZGWwzsMRObD$D9OMDZWWMRQg0B#B#B8###@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@kIV^vyzskVksmzGmkTkMVcKIzXsz    //
//    Q$Kix))xYczzYLILxLL<)xRgRgQ#@#gBB#QB##Q8##@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@yIIVmkLv*)zmIXsXVuXPuuzTYxxu    //
//    Q#WTY))xTlX33iyv)xxxYvcBQ#[email protected]#QQQ0g##B#@@@#@#@@@@@###@#@@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BVw}wTVyVLx;xl}VccYuwVLsVT}xx    //
//    0$MTWmmOBgOQBdQWIVYx)[email protected]@##@8B#B###@@@@@@@@@@@@@@@#Q###@##@@@@@@#@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@QLVXckwxLVwkmV}LwyVlxVuyTlxxxi    //
//    BDgd$ysgRbM8#[email protected]@[email protected]@##gQQ0Ggg$Q9O##B###@@#@##B#@@@@#B###@@@#0QQBB##BB#BBQgQ#@@@@@@@QOOOGZVvTx=!=^|YxkwlcVVXzzyT}Vur*^VLYxiyV    //
//    MbBQZsQBZKXZPKgbbZGOmO$DdzYlxv)r*)vcLr^~*#@@@@#B;v*~:,,--'-_.`!~,=!",'`.ZQB##O._--"::_.- `'__.,:v*^:[email protected]#QB#DxxY)*x)!:=:!:-!:,xVkzwVXyVTyTuVYVVIPzvIPy    //
//    [email protected]#gWPRwMMZOkcKZ9bmKksw|vv)!!=*:,-_;B#gBBgO'_-_,-.`'-_```"_'```   `GQD#Qg:--."):.-.``-.!__:*:|r|[email protected]@@@#@QT|xY::^xx|vr~))~-*|TwuTVuLuY=!v}zcXwyl3zx    //
//    MBB##QB##mMPdOg$QgWlXKkKIY=ixTTzYVx)):"!v#BQB#QZ!r*)=:_-.--``._``_:-'`,:$#[email protected]@@)"-"-)l:_::_,_:~=)xrLxr)#@@@@@@D|~<v)=_":,,--_-_-"=xullu}Vur^YyYlvvylmuu    //
//    BQQ9gQgK0zz}l}sODOGwLziuiLx}LXzIyx;||<[email protected]@@@@@RTz):v)-`-..``.-.-"=--'!)[email protected]#@@@_,-"_,i)!_::!;!;:*v^r=|^[email protected]@@@@@gxv*v^^_:!~===_")vxYc}TLxxxi*xulyl}Y}x)v)    //
//    QDRQDDObOmgIscwWOOZW}cyzGG3mTlysT}LGr"[email protected]@#@@@G;rVViY! --```.':_`''._,:[email protected]#@@@,:)<*vx<!_:":~*=:v)iwcc*[email protected]@@@@@QLiuyL|)L)ilTlTVlL)uVYTuxxxlivvVyul|vxvi;    //
//    #QgQ0sMQPu}x3wPg#8M$OmbO$$bPzTxVOQ0#@#B0Q#Q##@@#[email protected]@@@g|,:"-_",__,,,:==;;[email protected]@@BQ^r*^rX}!=!;<*|rx||[email protected]@@@@@@@@@@@@@@@BTzwI3ViLwkVVYcVXwXcwwkyVVkIVxVVY)}L    //
//    @@@@[email protected]@@@@@@@@@@#@[email protected]@@@@@@@@@@@@@@@#BBB#g#[email protected]@@#@@@@##@#@@@@@@#[email protected]@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@0lwVVVVXyXzXXyVkmz|VIIXVwTxv)^    //
//    @@#BOYY}x)vibGbdOQ8$kTzOcL#@@@@@@@@#@@#@@@@@@@@@@@@@@@@@@@@########B###@@@@@@@@@@@@@@#@##@@@@@@[email protected]@@@##@@@@@@@@@@@@@@@@@@#BKwwws3zsXIVcwIsVs3IsksmuT3d    //
//    [email protected]@#BR$dmwwWMVIkKIYv!^*}<*[email protected]@@@@@@@#B#@@@@@@@@@@##@##B#@#BQQBB8BQQQBBB#@@#@#@#@@@@BBQG8QB#QB#######QB#[email protected]@@@@@@#@#$g######QIywTxwXsLcL}lcwwsm3mIcVXyyM3    //
//    [email protected]#B09WmuL=kxmwwyr<*;=r^xVxVx:^^3Yl=^[email protected]@@@@@@mcrxlv**vY:,-,!!:!LdBOzxwgBB###dMg##G*!vvVLc)[email protected]@@@@@@@Rcv)TkRzx}VkVXVlXmz|)vLVIkzsKKIkyVkVkP0    //
//    Q#BBQdPWK}TV3uWWyc**^,:vlluVvx)*rx=!!:*[email protected]@@@@@#Tr!:":rL}r``'--*sg#P^-!!~^;vKYr^^*[email protected];[email protected]@@@@@@#XlL*wuir)}VI}XxvYlyxxwYuXIKmXKmkVIKcKPD    //
//    QMbBQgWwIx}zXwXIYv)^;",=;x*T)xlc}r^^,-:#@@@@@@@8mWXTYYywyx)XO#$Icr;=:,=;=:~v<<=^*)^rP#@$PziV)VwszsX|[email protected]@@@@@@BYlxruzuxLcVwVTVkkGMs3ZmIKGmMmMMGlVG3POP    //
//    RQ9#Q93PdGKliYyVYvr=;:^}*cT}x}cixx*=,,*@@@@@@@BumzG$QggQD$MWV^r*;^^)r^r|=~rDVx|)|)|v=*b#@#[email protected]#@@@@@@@#Vc})VzVz}lyyT}kwwI3IKKkmywIKzGMycVW3IMR    //
//    bO$##MzKD$mzcxV3}*s)*^xL~ullxzIkVm}[email protected]@@@@@@QLxYiTlivx;*r**~*v)<;**^)|)[email protected]<)xVR$DQ######[email protected]@@@@@@@cxVczVIMTx}TluVVlkzkVWyw}lVcYVwLLiucVVO    //
//    cVMPRmkW$Oi^YyssksKs*)*:r:v<|KY<!rx))[email protected]@@@@@@#sPsXzVTwy}kuwW}uVucv)[email protected]@@@@@@@@|rLyvv^iVLuTyIuuluVckcXcyTVlY}}uciLxxKM    //
//    VvuRQ0X$D3i**=TG)rvir*T^V^*x}[email protected]@@@@@#0*==*;^^ui)[email protected]}[email protected]|[email protected]@@@@@@@vrx^:=,,_~xT}}xYV}LcyXm3OOdwcIcVL|||)kw    //
//    bcsORGVXmkix}vvci*xr^=^|)*^^**xYw}[email protected]@@@@#8Pr;*rvYv||<|[email protected]}[email protected]@@@@@@@@Y::ir=-""-"c3K3WOMZs9XGVzkxr^^)uVzVLYLz    //
//    Q8KIwlckyXV}yiix"-:::"*v|^!^r*x}lXVmc}[email protected]@@@@@#Mx)vril^)):!*W#GywTr)r;;xIr*::=rvvi}xYx)TVR#kwVuyk}}[email protected]@@@@@@@3xryr:!_:-_!ks3kVVukzKuxLYv)*^rvYLTxx3i    //
//    ggMRKcyyzY**uYzur:!=!,~^)*:r)|ucyl}Xyx#@@@@@@Bz||^)));^x;*rwIvryu^)vvTuVTx=:;:rYrL)L*;[email protected]@@@@@@@@b*yY<":!,";YckVTyyTIPGKLwlxrr)lTTx)xv}l    //
//    #bVbP3sWMX*=urmmlY}yzlwzVTv*[email protected]@@@@@@@dyuxi*)<|x;*vxr)lV}rvuY=*)~<^!:~r)xvxxvrLkQQVusYyPPcTci}[email protected]@@@@@@$luVTTcr~rVz}iLL}VTTmOPyuVxxxLv}llTcT|z    //
//    XY}wV3GMkWz)sXXwykPIKkwYIwL^*[email protected]@@@@@@@GwlxTLwYlu|uXs)Lk}luxcx*;v^^;*^v)vLVkyyvivLxvws)Xb}[email protected]@@@@@@#vy)}uc}iVVcYlYcuYvLIV}xxLixxlzYylz}uyV    //
//    WYuVclLmMbIzGwGXVwssz}wcIyT)[email protected]@@@@@@@ukw)=:TVIX}ylkx;s###Q##QQBg$#8RgQQQ#[email protected]@@@@@@@IVrVuyylcyVl}xL))!<lwcvrv))))x|ysKwTmk    //
//    WVkTVVvymIsMMIdZXsPKsyIccw}|)T}[email protected]@@@@@@#wGIkyTzxVV)lssTYcTVT}gMrT}[email protected][email protected]*rrvxx|[email protected]@@@@@@@bu*cxuwcxTYivxixx)YXzVLiTx}xTVricwwXId    //
//    B##RbViswkXOOc9QPmGZMsVx))[email protected]@@@@@@BwwwkuVu)iY*)[email protected]#[email protected]@@@@@@@@Bx)Vr}Llxyli}uGsGuV}TLl}ciTVskVlsbbXI3    //
//    [email protected]@QBdD##[email protected]@@@@@@Or|civxv^vL^*}[email protected]^)[email protected]@@@@@@@@dPbOdWGKODb3m9ZOXsPkwI3KzsXm3zlmZyybW    //
//    [email protected]@@@@@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@Ri}YxxxLr|x^|YclxvvxxLO$zQVxzRVzbBMX#zxv=xTV}xXyVLmzcysywxi#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@RmOM    //
//    #@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@PccY||)v<|r)ul}xixYxVxObiO***):*)Oxv#z|)*xyu|xVywmmzImsmG|[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$PDM    //
//    #@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@s}xlVywy}ux)lTLLxYLxivOWT0xrr^**[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@KIdM    //
//    Q#RB#@[email protected]@@@@@[email protected]@@@@@@@YcY)iTluiVi)Li)*r^~;^^mmxVv*TxxYVzx}QWr)^|iYxYv)[email protected]@@@@@@@[email protected]@@@@gM09dMGVOZy    //
//    BBQ$b99BQ#@@@@@@wYsMVuVLT):|[email protected]@@@@@@Qvv)^~*))<*)))^^^<!=":^PVvy*!^);^|Y*|gl=<*|iY^!^;;[email protected]@@@@@@@B~=vcVT}T}VwIWzkTYuT}@@@@@yxv}y<x|PmT    //
//    [email protected]@@@@@GuimxxT|lxYwu=*zL}x)[email protected]@@@@@@#^vvr^^xi!;xxr^;rx!r*;^suvi)<)}v^|YxxOVv*=||YxLYc;)rv)[email protected]@@@@@@@@*-=;rviLv|xxxYxLx}[email protected]@@@@kiuk)}iviVv    //
//    Q#Q03D#@@[email protected]@@@@@QYI03uwPTivuur*})Y)*#@@@@@@@Q=r*<=^~):;xx~;!*Y^rx)rK|*x))YuxxLxxxclvr<))ivYTl<~;r^r:rxx)[email protected]@@@@@@@Y!:rv||v**[email protected]@@@@w}yuTVsuVcx    //
//    dGM$#@@@@#@@@@@@g*vRmWOGsVvxY~r}^}Yv#@@@@@@@B*xLxL)=;,~rr*~!!^^;*^vXr)L)vV|v*}ii)k}v^;^rrxvll**^rrvv)v*[email protected]@@@@@@@3,xiuTTxvr)lc}L)^))[email protected]@@@@XiT}xyk)ii}    //
//    DPI$##@#B#@@@@@#dIRBOGZMwx!YT^^^<xYT#@@@@@@@QY=:!Y)*r!^|xr~="!~~<vvzivYxL*^,_:*LYkLv|<x|uTLc*xVr^*xiYr<;[email protected]@@@@@@@GrYTVVLxxrvvxYxr)vxY#@@@@Pl}VVzw^v)}    //
//    swWQ#@@@##@@@@@#bG$#Bbb93cYcT|xz)xxT#@#@@@@@$i|<~L*rx;<xLi=^~^*)*vxLxv|ri*=",<:|)T)*^^vTx~<=Yxc|x|YTx~:)[email protected]@@@@@@@vrcTx)YLc}x*rV}[email protected]@@@by|)*lv:Y;*    //
//    Q#@@@@@@@@@@@@@#[email protected]@[email protected]@[email protected]@@@@@@@#xXl|xiviv*xxx*vx!=YLTT))x|rvV="!^xT))rvrrzw)vuxlcl)xxxT))!v}#@@@@@@@@r:rrrr==*lT,=*lyYx)[email protected]@@@MvLvxwy}:~V    //
//    #@@@@@@@@@@@@@@#[email protected]@@###[email protected]@@@@@@@#}YVuizYL)xx|xxx)=x)lxVL|x||)iv<[email protected]@gsVc)iuv*ruTixxY<#@@@@@@@#i)l)<)xxixv)kxlxyyKW#@@@@B$Q$gBQ$)cl    //
//    @@@@@@@@@@@@@@@@g##@@@##@#B####@#0$R#@@@@@@@@KMzmuzuTvvxvvYlxlLrl}}Y)v)ivT}[email protected]#LTVyuvVx|[email protected]@@@@@@@@G}[email protected]@###BQB####ggd    //
//    @@@@@@@@@@@@@@@@##[email protected]@@@@@#@###[email protected]##Qg#@@@@@@@@09MOKPVkxTLx}VYLiYLxLlzixvvu;)Llx}i}[email protected]@@k}VVuwyVx}xxi}lx}#@@@@@@@#MTwKX3Z0KkIX8$0WXMZ3d#####$Z0D##dsQQ    //
//    @@@@@@@@@@@@@@@@@##@@@@@@@@@@B#@@@##@@@@@@@@@#BM9GcIuimI}cuucTTkc^r}L}lx}Y|iTyV}[email protected]@@@mlkzVcvVTY|vxcVYx#@@@@@@@BOsxLzmmZmZXsdWwOz3bGP####B$D9BB#dGQ9    //
//    @@@@@@@@@@@@@@@@@##@@#@@@@@@@#@@@@#@@@@@@@@@@@#@@#g8DZ$OwzczkRKMOdRsy}yixVTLVuVTcK}[email protected]@@@Qz}yT~};ix=*Lv*|[email protected]@@@@@@@#8OTvwVV^lOYylKsyysZ3PB##B80RdOQQ$gdQ    //
//    #@@@@@@@@@@@@@@@@@[email protected]@@@@@#@@@@g0#@##@@@@@@@@@#[email protected]@@@@@@@##@@@@@@@@BdVX}ucyuxiMuO$W0#@@@@kTl}lT*=!<ukVx*[email protected]@@@@@@@@#QGmVvObZ9OMOR9MM$99b$QgDMQdMZ$QO$sZ    //
//    #@@@@@@@@@@@@@@@@##@@@@@@[email protected]@@BQ#@@[email protected]@@@@@@@@83d####@#@@@@@@@@@@@@@@@@@@#@###@##[email protected]@DVVwl=::,"[email protected]@@@@@@@#$ZxVX=GcMMGzkKPZK3OdcZRdRMDRbgQQQ#BB    //
//    @@@@@@@@@@@@@@@@@#@@@@@@@8#@@@#[email protected]@#@@@@@@@@@[email protected]@@@##@@@@@@@@#[email protected]@w*ix^r_:,=^[email protected]@@@@@@@#gk!=T~w}uKIi^YusX3Md|VdD800$M9$B#B#Q    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BB#@@#@@@@@@@@@[email protected]@@@@@[email protected]@@@@@@QyXkcD#liQO;:!L~;<rVv)[email protected]@@@@@@@#$WVrx^rw}yMP)xXlx)cKWWMgM90#@@QB##QMI    //
//    @@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@B#@@@@@@@@#[email protected]##BOwVKK3PWXPGQB#[email protected]##@#[email protected]@@@@@@@#gODZYLwmzyKXIG0dkxZbZXlVxuG8#[email protected]#@BQQs    //
//    @@@@@@@@@@@@@@@@@@#@#@@@[email protected]@@@@@@@@#[email protected]@@@@@@@Q$ZZ$QPP88R$bbZ9ORg9$kMzk3yMWZ9VZOWsMG##@@@@BQKixPBBBBRB###@@@@@@@@@##Q9M3M9M8ODQ#@#$$MDgg8QgD0BBR80gbzzY    //
//    @##@@@@@@@@@@@@@@@@##@@@@#@@@#@#@@@@#@@@@@@@@##$BB#QBB#BBMZQDgs$R$bbOO0MB##[email protected]@@@@BBB$ODQ##QB#@@@@@@@@@@@@@#B$$WQQ##Q8QB##BB#@@#@@@##@@gb9Omml)    //
//    #@@@@@@@@@@@@@@@@@@@@@@#@#@@@@@@@@@@@@@@@@@@@#@@@@@[email protected]####Qg###[email protected]@@#@##[email protected]@@@#@#@#[email protected]@#[email protected]@@@@@@@@@@@@@BMdDG$Q#g$Q##B##@@@@#@@@##@@@8QgWKks    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@####$##@Q#gQ##@#[email protected]#8$RBBg#@@@[email protected]@QQ0Q#@@@@@BQ##[email protected]@###@@@@@@@@@@@@@8Pb9MRM$GdggB0BQBB####@@@#@##OQQgB0O    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@####$Q$BBBg$B#@#Q##QQB##8Q##@[email protected]##B#$Q#@@@@DgQ#BQQ##gQ###@@@@@@@@@@@BQ#Q9$Z0MMO9$OgQQR#[email protected]@@@#@#@@#BOZ    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@####@#[email protected]#@@#B#@###g##@QQ#@[email protected]@@##gQQ$Q$D##QQ##@@@@@@@@@@@@Q$g$O8g8#$gQ09Q##B#@#[email protected]#@@@@#@BgZ00g    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@#@Q#QBQQ#####Q#@#@#$##@BQQB##[email protected]@@@##B#8QQ$BBg$B##@@@@@@@@@@@B8gO9D$B#Q$BBQQ#@@@@@###BQ#@B#8Q0bW9    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@#[email protected]@@@@##@8#QB#QB#@@[email protected]@@@@@@@@@@#@##BBBBBQB##@@@@@@@@@@@Bb3Pm3s$0DdBBBQ##@@@@@@@##QDKyGbR9MO    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@@@#@@@@####QB##@[email protected]@@@##@@@@@#@@@@@@@#####@@#@@@@@@@@@@@@@@#BBQOR9MGzsZ8Q$B#@##[email protected]######B$QBQQB$    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@#@@#@@@@#@@@@@####B#####@@@#B#@@@@@#@@@@@@#@##@@@@@@@@@@@@@@@@@@@###B#####Q####[email protected]@@@@@@#[email protected]#######@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@@@@@@@@@@##@@@@#@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@##Q#@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#B#@@#@@@@@##@@@@@@@#@@@@@@@#@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@@@@@#@@@#B#@@@#@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@@#@#@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@###@@@@@@@@@@@@@@@@###@#@@@@@@#@#@@@@@@@@@@@@@@@@    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FMCHAOS is ERC721Creator {
    constructor() ERC721Creator("feel my chaos", "FMCHAOS") {}
}
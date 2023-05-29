// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Velocity Motion Spectrum
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    v**?lc&:&$$$$#$rj#$u8%Mxf$8$|vc\B]*BMn|W$rM$z8%[#[email protected]]$$$B/@$z/*Wrt$#[email protected]/B$B%Mc/[email protected]&$v\ctMj/$v    //
//    $[*x|z8(&$$$$-_~v$$uM\\)\|(\1\(|\*[email protected]@[email protected]*{#[email protected]$$$$%$)crf%$$$#vu$$$%B?%$$$$$z$\\\)\1\)\\1\n$$v    //
//    @vMMv$$$$$$$vrM$$$$cBjxnnnuuununnW%@&$$$$$$rM$$$$8$8$$$zf[W$$$$$$$$&$$$$$$$$$$$$$$#$nrnnuuuuuunn*[email protected]    //
//    $)#@%[email protected]$$$$jv$$$$$$&$$W><_1xB$$$$$$$$M$$$$B{B$$$$$$$*$$$$$$$$$$$$$$$$c    //
//    *j*\?zM,&@@@@[email protected]@@@@[email protected]@@@@@@[email protected]@@@@@%#@@f\*@#&[email protected]@@[email protected]&@[email protected]*&@[email protected]@@@#@@#-%[email protected]%[email protected]@@@[email protected]@@@@@@[email protected]@@@@@@v    //
//    8&#&#[email protected]$$$$$c$$$$$$$$$$$$$$$BWf\%B#$*%@[email protected][email protected]$$$$M#-%$*[email protected][email protected]$$$$*$$$$$$$$$$$$$$$$z    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$c]!~z$$$$$$$$$W]$%$$%$$$$$$$$$$M)i<{$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$zM$$$$$$$$$$$$$$$$$$$$$$$$$$$$$Wc$%$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$B&[email protected]$$$$W&[email protected]$$$$W&B$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    [email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    $$$$%$$$$$$$$$$$$$$$$$$$$$$$Bx\||@[email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$)??($$    //
//    $%8$<M$$$x&$$$c+l<&%[email protected]$$$$$$8f$$n%[email protected]$$*@#[email protected]?8$$$$B?u($8$*%$$$$8]@#$%$$$$$$$8n%8$&    //
//    u**];c$$(uWMx$M%&-%#$v)$$$xM$%?*-%z$[#$$$$$$xI$|xW&rx/)j\Bf[W%r$$$$M&$&B$*8{@$$$$8%cn$#%>8$$$$Mtj/$v    //
//    $}*r\c$$%$$$B8c|u%$#$*[email protected]@{z$$$$z$%$$$$$$$zI$%$$$Bj+IiB$f[$&M$$$$(\\|$$*Wn$$$$[u$8$$#Mf$$$$[W$$$$v    //
//    @zMMv$$$$$$$$uc$$$$&$&$$Bx|[email protected]$$$$$M$$$$$$$$$v;[email protected][email protected]){%#uB$$$]\x%$$W$$$$$$[i~/$$&$$$$$$$$$$$$c    //
//    $1#[email protected]`  +${  .%$n      $$$f  ^$$$cjW:.    `(W|$$r^    ./8B{  ^$$8       |r?  .v-  `*$nn$$$$$$c    //
//    *j*\[email protected]+j  .x.  \$$8.  `^,[email protected]  ^$&+MB'  ""1.  ]%8\   _+"t$vz_  `[email protected]   (\8$*|.    [email protected]@zWz$$$v    //
//    8WMWW$$$}[email protected]*}  '  -M$$8.  ^^,@@$f  ^_#$z$.  ~~&'  ;$#)  .zr+W8|f<  `@@$$$   8$%[email protected]  ]%[email protected]$$$z    //
//    $$$$$$$$t>i|$"   ^$$$v).     n$$j     `r$j'      `($$$~     .|>({  ^$$$$$   1~x$$$$'  z8{l<*$$$$$$$$    //
//    $$$$$$$$vB$$$8\\\8$$$$$\111(\8B%#1|\|\nvn*$v1+_(M%%%@B%Wt[?{xcnz&\\xB%%@$|{][email protected]@$$$r\\B%z$B$$$$$$$$$    //
//    $$$$$$$$%[email protected]$$$$%I   `$W    |$['     "v'      !^  )$1'     ^n$,  .*/  :B$$$$$$$$$$%%B$$$$$$$$$    //
//    $$$$$$$$$BB$$$$$$$$$$$Bl    ],    |[  .\n>  .rx^  ixM^  )(  .(n_   M,   .?  ;[email protected]@$$$$$$$$$    //
//    $$$$W$$$$$$$$$$]<M$$$$$!  ,   .^  |<  '[email protected]   M$,  [$$^  )?  'W$x   z,  "    ;[email protected][email protected]$$    //
//    $%8$>W$$$$$$$$$B[&$$$$$l  r'  -,  |B,      .)$$,  lW[^  ?B.       ~v,  n+   ;$]l>t$8$$$$$$$$W]<l~{$&    //
//    uz*_!v$$1v$$j***c$$$$r&v([v)?lru(~nxcr>+l-{f8$$]]{f&Bj((t%8*}-<_,#nc~)[M_t(<[email protected]#[email protected]$$8f$&jMxn/$v    //
//    $[*x|*$$jW$[. .  ~$$.    .,Mx"      BB}+'    .[?       _v.    ."[);  #M$1  *@!   ($zv   ^$%M?vcc$$$v    //
//    @cM&z$$$B$$. ^uBv$$$. <$c  ]$! 'Mujn8$^  )B$Mf$$$n` ^$$$z. Ivn. :c]  #&$|  MB; . .W#` . `t_$$$$$$$$c    //
//    $1#@&$$$$$$u,'  ')$u.  . .,n$!  ...`W$  `[email protected]#c%@^ ^$$$c.    .I&$/  MW$|  [v? '> `: ,' '\x$$$$$$$$c    //
//    *j*\?z$$$$[[[Mn` .r1  ^*@#c_W: 'l-{?u$,  >/r,`/)8$` ^$$$v. >f  ~$$c  Ijv" [email protected] '@`  '8^ `ctBu$MW$$$v    //
//    %&M&M$$$$$z".  .^n\)' <*$W/#W>......t$z/".  ..^M$$".,$$$z`.-$n'.>$$j".  .,[email protected]+.^$*'.u$,.:$$%[email protected]$$$z    //
//    [email protected]$$$$$$$$$$$&$$#@$$$$$$$$$$$$8$$$$$$$$$$$$$$$$$$$$&[l+&$$$$$$$$%]B$$$$$$$$$$$$$    //
//    $$$$$$$$]~_t8$$$$$$$$$$$$$$$$$$$$r^;|)t$$$c$$$$$$$8?$$$$$$$$$$$$$$$$$$$8*$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    $$$$$$$$$$B$$$$$$$$$$$$$$$$$$$$$$$$+:1~f$$l$$$$$$$$"%$$$$$$$$$$$$$$$$$$$&&[email protected]$$$$888$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$<^M$$$+($$B%%$$-+$$$$$88$WB$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    $$$$&$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$>)1`>};"'):jizuM&'Wt%{$<.v'^?[@[email protected][email protected]/@$$$$$$$$j()((f$$    //
//    $%8$>[email protected]_c#[email protected]&$?#vz8?M$8Wu/1$88`^u .`,'.`l`$`,^I _1 ,i [`}W$zc$$$$$$%c$$r#$zc$$$$$$$**v**z$W    //
//    uz*-lv$$}x$$t%[email protected]#[email protected]*$%%ut%%$[*vrz`x#%^'^"'"{I^'^,f?^l`''i'^".``Ivn)&$fW?z?cc$W-xu)&$$jW$${nu[$/~$v    //
//    $[*x|[email protected]]W$$W$$#$1)1{1})[)}))@r+}*&8%"rx){#z/{/'r/)<?l`%,#[email protected]@$$B8-!i)[email protected]@$$$B$$$)zu1$1[$v    //
//    @[email protected]<~+{$$W$cz*z**#**z**BB&$$$$$$*z$$$$*vx"xf?<>$-M~8$$*[email protected]$8B$$}n$$$$$$$$$$$$$$$$$c    //
//    $1#B#$$$$$$${88$$$$$$#[email protected][email protected]$$$$$$W$$$$W1$$$$$$*$$ci>-/[email protected])W($$z$$$$([email protected]$$]x$$$$$\vc+?z}:/;]$c    //
//    zr*\]*$$$$[c8$c%v$$$$*$$$$$$$f8$$$$$$#$$%~&@%[email protected]$$z$$B*?cccMW*%@$$c$$(x&$c&#$$$&[email protected]$$$x#[email protected]$u#$v    //
//    8&MW&$$$}cB#[email protected][email protected]$W&@$$$#$$B$$$$$#%@$$$$*r|%&[email protected][email protected][email protected](8$MW$$$/}<>>/$$*    //
//    $$$$$$$$/~i]B$$$$$$$$$$$$$$$$$$$$$$$$$$)i>f$$$$$$$$$*{$$$$$$$$$$$$$v_!-&$$$$$$$$$$z}i<[&$$$$$$$$$$$$    //
//    [email protected]$$$$$$$$$$$$$#8$$$$$$$$$$$$$#M$$$$$$$$$$$$$$$$    //
//    $$$$$$$$B%W$$$$$$$$$$$$$$$$$$$$$$$$$$$$8%&$$$$$$$$$$$&[email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    [email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    $$$$#[email protected]@@MWMM##MMW&%$$$$$$B#M$$$$$*n([email protected]@$$WxB8WMM##*#MW$$$$$$$BM&%B$$$$$Mjt\(#$$$$$$$$$$$$$$$$$$    //
//    $%8$>W$$&?WB$$$$$$8?8$r\$8&<[email protected]&u#[email protected]&[email protected]$z#$tf$\n${c$n*[email protected][email protected]$$zcvxf$$zBu_+-}v&$$$$$$$$$$&rfff8M    //
//    nM*~in$$%|(j$$$$$$8%$W&@$#%@$$$$n%$$$/[/1?$$#$M&B%[email protected]%[email protected]%+8#8u-%[email protected]#cz?nt{{[email protected])x$$$$$$$c*unW$v    //
//    %1#n(#$$f$B$$$$$$$W_i;]$$MWfjfjr&[email protected]|$$M$r[-~i~!<>>~+~?[[email protected]$$$z$B$$$$$$$$j__t$$     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VMS is ERC721Creator {
    constructor() ERC721Creator("Velocity Motion Spectrum", "VMS") {}
}
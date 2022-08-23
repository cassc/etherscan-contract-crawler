// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: M O O N
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    [email protected]rrxrxxrrrxrrxrrrxxnuv#$$$$$$Bvunnrrrjrxnnuv%[email protected]$$$$$$*vunxxrrrrrrrrrrrxxrrrrrrrrrjjjrjjffjffffff    //
//    xxxxxxxnxxxxxxnnxxxxxxxxxxxxxxxrxxxxxxnuuv*$$$$$$&vunnxxxxxxxxrxxrrrrrrrrxxxxxrrrxnuvM$$$$$$trunf`>jr(""?n\v$$$$$$WvuunxxxrrrrrrrrxxxxxxxrxxxrxxxxnuuvW$$$$$$#vunnxrrrrrrxrrrrrrrrrrxxxxrrrjjjjjjjjjjjfj    //
//    xxxxxxxxxxxxxxxnxxxxxxxxxxxxxxxxxxrxrxnuuv8$$$$$$cvunnnxxxxxxxrrxxrrrrrxrxxrrxxrxnnuv%$$$$$B-</r"`',j)^`<n]>&$$$$$Bvvunxxrrrrrrrrrxxrxxrxxxxxxrrxxxnuuc$$$$$$8vunnxxrxrrrrrrrrrrxxrxxrxxrrrjjjjjjjjjjfjj    //
//    xxxxnxxxxxxxxxxxxxxxxxxxxxnnxxxxxrrrxxxnuz$$$$$$&vunnnnxxxxxxxrrxxxrrrxxxxxrrxrrxxuu#$$$$$$Mvunxrrjjrrrxxnuu#$$$$$$#vunxxrrrrrjrrrxxxrxrxxxxxxxxxxxnnuvW$$$$$$zvunxxrrrrrrrrrrrxxxrxxxxxxxxxrrrrrjrjjjjf    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxrjjxxnnu%[email protected][email protected]@$$$$$%vunnxxrrrrrrrxrrrxxrxxxxxxxxxxxxxxrrrrrjj    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxrrrjjjrxnuM$$$$$$&vunnnxxxxxxxxxxrrrrrrrrrxxrrrrxxnuv&$$$$$$MvunxxxxxrxxxrxxxnuM$$$$$$8vuunxxrrjjrrxxrrxrxxxxxxrrrxxxxxnuvW$$$$$$Wvunxxrrrrrrrxrrxxxxxrxxxxxxxxxxrxxxrrrrj    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxrrjjjjrxnz$$$$$$$zvunxxxxxxxxxxxxxxrrjjrrrrrrrrrxnuu#$$$$$$$cvunxxxrxxxxrrrxxnuv$$$$$$$Mvunnxrrrrrrxxrrrrrxxxxxxxxxxxxxxnuz$$$$$$$*vunxxxrrrrrrxxxxxxxxxxxxxxxxxxxrxxrrrrj    //
//    [email protected]$$$$$$%vuunxrxxxxxxxxxxxrxrrjrrjrrrrrxxnuz$$$$$$$8vunxxxxrxxxxxrxrrxnu&$$$$$$$zvnnxxrrrrrxxrrrrrrxrxxxxxxxxxxnnuv%[email protected]    //
//    xxxxxxxxxxrxxrxxxxxxxxxxxxxxrxxxrrrxnu%$$$$$$$MvunnxrrxxxxxxxxxxxxxrrrjjrrrxxnnucB$$$$$$$*vunxrxrxxxrxxxrrrxnuz$$$$$$$Bcunnxrrrrrxxrxrrrrrrrrxxrxxrxxxnuv#$$$$$$$%vunnxxxxxxxxxxxxxxxxxxxxxxrxxxxxrrrrxx    //
//    [email protected]xxxxrrrrrrrxnnuv8$$$$$$$Bvunxrrrxxxxxxxrrrrxnnv%$$$$$$$%[email protected]$$$$$$$&vunxxxxrxxxxxxxxxxxxxxxxxxxrxxxrrxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxrxxxxrrjxxxxnuuz$$$$$$$$Wunnxxxxrxxxxrrxrxxxxrxrrrrrxxxnuu#$$$$$$$$Mvunxxrrxxxxxrrxxrrxxnu#$$$$$$$$MvunxrrrrrrrrxrrxxxxxxxxrrrrrxxnuvW$$$$$$$$*uunxxxxxxxxxxxxxxxxxxxxxxrxxrrxxxxxx    //
//    [email protected][email protected][email protected][email protected]xxxxxxxxxxxxrxxxxxxxrxx    //
//    xxxrrxxxxxxxxxxrxrxrrrrrrrrrxrrrxnu&$$$$$$$$&uunxxrrrjjrrrrrrjrrrrrrrxrrxnnuuv%$$$$$$$$WvunxrrrrrrrrrxrxxxxrxxnvM$$$$$$$$Bvunnxrjrrrrrrxrrxxrrxxrrxxxxxnnuv&$$$$$$$$8vunnxxxrxxrrrrrrxxxrrxxxrrrxxxxxxxx    //
//    rjxrrxrxxxxxrxxxrrxrxxrxxxrrrxxxnuc$$$$$$$$$cunnxxrrjrjjjjjjjjrrrrrrrrxrxnnuv*[email protected]$$$$$$$$*vunxrrrrrrrrxxrrrrxrxrrrxxxxxnuuc$$$$$$$$$zuunxxrrrrrrrrrrxxxxxxrrrrxxxxxxxxx    //
//    jxxxxxxxxxxxxxrrjjrxxxxxxxrrrxxxnu&$$$$$$$$%unnxxrrjjrrrrrrrrrrrxxxrrrxrxnnuv%$$$$$$$$&vunnxrjf/ttffjrrxxxrrrxnuvW$$$$$$$$%vuunxrrrrrrrxxrrrxrxxxrrxrxxxnnuv8$$$$$$$$&vunnxrrrxrrrrrrrrrxrxrrrxrxxxxxxxx    //
//    jxxxxxxxxxxxxxrrrrrxxxxxxxrrrxxnnv$$$$$$$$$Munxxrrrrrrrrrrrxrrxxxxxrjrrxxxuu*$$$$$$$$$*vunnxrrf/ftfjjxxxxxxrrxnuv*$$$$$$$$$*vunxrrjrjrxxxrxrrrrxrrrrrrrxxnuu#$$$$$$$$$cuunxxxxxrrjrxrxrrrrrrrxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxrrrrrxxrrjjrxnuM$$$$$$$$$cunnxxrrrrxrrrrrrrrxrrrxrrjrxxxnu&[email protected]$$$$$$$$8vuuxrjrrrrrxxrxrrrrrrrrrrrrxxnnuv$$$$$$$$$Wvunnxxxrrrrrxxxxrrrrxxxxxxxxxxxxx    //
//    [email protected][email protected]$$$$$$$$Bvuunxxxxxxrrxrrxxrxxrrrrxnuv%[email protected]$$$$$$$$Bvunnxxrrrrrrxxxrjjrrxxxxxxxxxxxxx    //
//    [email protected]rrrrrrrxxnuc$$$$$$$$$%vunnxrxxxxxxxxrrxxxrrrrrxnuv8$$$$$$$$$zunxrrrrrrxrrrrrrrrrrrrxxrrxxxnuvB$$$$$$$$$vunnxxjrrrrrrrrrrrrxxxxxxxxxxxxxx    //
//    [email protected]rrrrrrrxnnu*$$$$$$$$$%vunnxxxxxxxxxxrxxxrrrrjrxnuv8$$$$$$$$$#unxxrrrrrrrrrrrrrrrrrrxrxxxxxnuvB$$$$$$$$$zunxxrrrjjjjrrrrrrxxxxxxxxxxxxxxx    //
//    [email protected]rrrrrrrxnnuz$$$$$$$$$Bvunnxxxxxxxxxrrxxxxrrjrxxnuv%[email protected]$$$$$$$$$cunxrrjjjjjrrrxxxxxxnxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxrrrrrxxnnuv%$$$$$$$$$*[email protected][email protected]rxrrrrrrrrxxnuuz$$$$$$$$$%vunxrjjjjjjrrxrrxxxxxxxxxxxxrxxrr    //
//    xnnxxnxxxxxxrxxxxxxxxxxrrrrxrxnnuM$$$$$$$$$BvunxxxrrrrrrrrjrjjjjjjrrjrrxxnnuW$$$$$$$$$8vunxxxrrrrjrrxrrrrrjjrxnuv&$$$$$$$$$&unxrrjjjjjrrrrrrrrrrrrrrrjrxnnuv%$$$$$$$$$Munnxrjjjjjjrrxxxxxxxxxrrrxxrrrrrr    //
//    [email protected]$$$$$$$$$Mvunxxxrrrrrrrjjjjjfjjjjrjjrrxnnc$$$$$$$$$$*unxxxrrrrrrrrrrrrrrrxxuvz$$$$$$$$$$cunxrrrjjrrrrrrrrrrrjrrjrrrrxnuu#[email protected]    //
//    xxnnxxxxxxxxxxxxxrrrrrxrrrrrrxxnnu*$$$$$$$$$$*vunxrrrrrrrrjjjjjffjjjjjjjjrxnu#[email protected]@$$$$$$$$$Munnxrjjjjrrrrrrjrrrjjjjjrrrxnuuz$$$$$$$$$$*unxrrjjrrrrrrrrxxxxxxxrrrrrrjfffff    //
//    xxxxxxrrrrxxxxxxxxxrrrrrxrrrrrxxxnuM$$$$$$$$$$Mvunxxrrrrjjffjjjjjfffjjjfjrrxnu&[email protected]*vunxxxrrrrxrrrrrxnuu*@$$$$$$$$$&unnxxrjjjrrrrrrjjjjjjjfjjrxnnuu#$$$$$$$$$$Munnxrjjjrjrrrrrrrrrxxxxxxxrrrjftt/t    //
//    rrrrrxxrrxxxxxxxxxxxxxrrrrrrjrrrxxnuW$$$$$$$$$$8vunxxxrrjfffjjjjjjjjjjffjjrrxnv8$$$$$$$$$$WvunnxxxrrxxrrxxxuuM$$$$$$$$$$%vunxxrjfjjjrrrrjjffjfjjjrrxxnuv&$$$$$$$$$$&uunxrrrjjjrrrrrrrrrrrrxxxxxrrrffftft    //
//    [email protected]*uunxxrrjjfjjjjjjjjjjjjjjjrxxnu8$$$$$$$$$$Bzuunnxxxxxxxnnuc%$$$$$$$$$$8vunxxrrjffjjjrjjjjjjjjjjrxxxnuzB$$$$$$$$$$&unxxrrjrjjrjjrrrrrjrrrrrrrrrrrjjffjff    //
//    xxxrrxrrxrrrrxrxxrxxxxrxxrrrrrrrrrxxnuM$$$$$$$$$$$&vunxrrjjfjjjfjfjfjjjjjffjrrxnuW$$$$$$$$$$$WvunxxxnxnnuuM$$$$$$$$$$$&unnxxrjjfffjjjjjfjjrjjjjjxxnuv&$$$$$$$$$$$Munnxrrjrjrrrrjrjrrjrrrrrrrjjrjjffftfjf    //
//    [email protected][email protected]#unxxrjjffjjfffffjjjfffjjrrxnu*@$$$$$$$$$$B*unxnnnuuzB$$$$$$$$$$$#unxxrjjjfffffjjjfjjjjjjjrxxnu*@[email protected]    //
//    xxnnnxxxxxxxxxxxxxxrrrrrrrrrjrrrrrrrrxxnv&$$$$$$$$$$$%cnxrjjjjffffjfjjjjffffjjrrrxuv8$$$$$$$$$$$&vuuuuv&$$$$$$$$$$$8cuxxxrjjjffffffffjjjjjjjrrxnuv8$$$$$$$$$$$&vnnxxrrjjjjjjjjjjjjffjjjjjffjjjjjjjjjjjfj    //
//    [email protected]#nxxrrjjffffjfjjjfffffffjjrxnu*@[email protected]#vv*%@[email protected]*uuxrrrjjfjffftjfffjjjjjrrxxnu#@$$$$$$$$$$Bzunxxxrrjjffjfjjjjfjjffjjfjjjjjjjjjjjjjrjjj    //
//    xnxnxxxxxxrrrxxxxxxxxxrrrjjjjrjjfjjffffjrxxuM$$$$$$$$$$$Bcnxxrrjffffjjffffffffffffjrxuv&$$$$$$$$$$$%W%[email protected]@$$$$$$&vunxrjjfjfjftfffffffjjjjrxxnuc%$$$$$$$$$$$Wuunxrrrrrjfjjjjffjjjjjjjjrjjjjjjjjjrrrrrrrjj    //
//    xxxxxxxxxrxrxxxxxxxxxxrrjrjjjjfftfffttffjfjrnc%$$$$$$$$$$$WunxrjjjfffffffjjfftfftfffrxnuzB$$$$$$$$$$$B8%[email protected][email protected]*unxrrjfffjfjjfffffffjfjjrxnnuW$$$$$$$$$$$Bzunnxrfffjjjjrrrrrrrrrrrrrrrrrrrrrrrrrrrjrrrrj    //
//    xxrxxxxxrrrrxrxrrrrrrxrrrrrjrrrjfffftfffftffxxn#[email protected]*nnrrjjfffftfjjjfftftttfjrxnnuW$$$$$$$$$$$$%8%[email protected]@[email protected]$$$$$$$$$$$Munxrrrjfffffjjjjrrrrxrrrrrrrrrrrxrrrrrrrrrrxxrj    //
//    xxxxxrrrjrrjrjjjjrrjrrrxrrrrrrjjjjjftfffffffjjxnv%$$$$$$$$$$$&vuxrxrrfffffjffttfttttffjrxnuzB$$$$$$$$$$$B8%8zunxxrrjjjffffffjfffjfjjjjrxnu&$$$$$$$$$$$%vnxxrrrjrjftfjjjjjjrrrrrrrrrrrrrrrxrrxxxxrrrxxxrj    //
//    [email protected]unxrrrjfjfffttffttttftfjrxnuc&[email protected]$$$$$$$$$$$Muxxrrrrrjjjttfjjfffjrrrrxrrrrrrrrrxxxrrxxxrrrrxrrr    //
//    xxxxxxxrjjrjjjrrrrrjrxrrxxxxxrrrjjjjjjffffffffjjrxucB$$$$$$$$$$$Wunxrrjffffffftttttttffjrxnv*8%$$$$$$$$$$$$MvnxrjjffffffffffffjjjjjrxnuM$$$$$$$$$$$Bcnxxrjjjjjrjffffffffffrrrrrrrrrrrrrrrrrrrrxrrrrrrrxr    //
//    xxxxxxxxrrrrrjrrjrrrrxxxrxxxxrrrrjjjjjjjjjffftffjrxnuW$$$$$$$$$$$8vnxrrjjftfffffttttfffjrxuMBB%8B$$$$$$$$$$$&uxxrjjffffffftfffjjjjrxnv8$$$$$$$$$$$Wunxrrjjjjjrrrrrjffffffjjjrrrrrrrrrrrrrrrrrrrrrrrrrrrx    //
//    xxxxxxxxrrrrrrrrrxxxxxrrrxxxrrrjjjfjjjfffjfffffffjjrxnc%[email protected]@B%8%@$$$$$$$$$$%uxxrjjjffftfffffjjjrxnvB$$$$$$$$$$%cnxxrrjffjjjrrrrjfrjffffjjrrrjjjjjrrjrrrrrrrrrrrrrrrrrr    //
//    xxxx[email protected]cnnxrjfjfjjjjfftfjrxu%[email protected]%[email protected]$$$$$$$$$$Munxrjjjjftfjjjjjrfjjjjjjjfjjjjjjjjjrrrjjrrrrrrrrrrrrrrrr    //
//    [email protected][email protected]%[email protected]%*#$$$$$$$$$$%[email protected]jjjrrrjjrrrrrrrrrrrrrrrr    //
//    rrrrrxrrrrrxxxxxxxxxxxrrrrjrrjjffftfftttffffffffffffffjrxnc$$$$$$$$$$Wnxrjjffffjfjjjrrx*[email protected]*vv*$$$$$$$$$$*nxrjffffftffjjrxnM$$$$$$$$$$cnxrrjjfffjjjjfjfjjjjfjffjjrrjjjjrjjjjrrjjjjrrrrrrrrrxxxxrr    //
//    rrxxxxxrrxxxxxxxxxxxxxxrrjjrrrjjjffffffffffffffffttttfjjrxu&[email protected]%$$$$$$$$$8uuuu%[email protected]$$$$$$$$$&unxrrjjfffffjjjjjjffffffjjjjjjjjrrjjjjjjjjjjrjrrrrrrrxxxrrr    //
//    rrrxxxxxxxxxxnxxnxxf:,,,,+frrrjjjfffffff/I,,,,,\ftttttffrxnz$$$$$$$$$$znxf[I"`'..''^;]r$$$$$$$$$$MunnuM$$$$$$$$$$vxrjf/];"`'..'`^lf%$$$$$$$$*uxxrjjjffffffffj_,,",;)fjjjjjjjrrr~,,,,,,{jrrrrrrrrrrrxxrxx    //
//    rrrrxxxxrrxxxxxxxxxx/}'   `frrrffjjjfjjt`   '_|fffttttffrrxv$$$$$$$$$$z{^. `I?{)1?l`   "[email protected]$$$$$$$*uxnu*$$$$$$$$$$vnr[^. `I-1(1?l^.  "[email protected]$$$$$znxxrjfjfffftfffj/)I    ^)jjjjjjrrrt(: ._|fjjrrrrrrrrxrrxxxr    //
//    jrrrxxxxrrxxxxxxxxxxxr,    "jrjftffjfjt^    :ffffffttfffjrnc$$$$$$$$$#`  ,\fftttffjrt;   `z$$$$$$#unnn#$$$$$$$$$$u\`  ,|tttffjrrxr_.  `z$$$$znxxjfftffffffffjff\. .   ,trrrjrrrrr| 'jjrjrrrrrrrrrxrrrxxr    //
//    rrrrxxxnxxxxxxxxxxxxxf' ;   ,jjffjjjff, "'  `tffjffffffjjrn#$$$$$$$$n.  >jjffftffffjrx).  .n$$$$$WunnuW$$$$$$$$$&{.  iffffffjjrxxn8c.  .n$$$Munxrjjfffffffffjjj/..(:   .ijjjrrrrr| 'jjjjrrrxrrrrrrrrrxxr    //
//    jrrrxrxxxxxxxxxxxxxxx( .fi   lrjjjjjjl `/,  .\fffffffffjrxn&$$$$$$$8'  `jjjffffffffjrxn]   `B$$$$%uunu%$$$$$$$$$x.  `fjffffffjjrxnz$f   `B$$8unxrjjfffjffffffff\../j(^   '?rrrrjr| 'jrrrjrrrrrrrrrrrrrrr    //
//    rrrrrxrrxxxxxxxxxnxxxl "xr:   <jrjrj+ '\f]   [email protected]$$$$$$$\   :rjffftftffffjrxr'   [email protected]$$$$$$$$$%-   :jfjffffjjjrxxuBB'   [email protected]\..\jjf]'   `)rrrr| 'frrrjjrrrrrrxrrrrxxr    //
//    jrrxxxxrxxxxxxxxxxxxr` -xrj"   -jjr[ .(ff\.  ,ttfttffjjrxnM$$$$$$$$1   "jjjffffffttfjjrr'  [email protected]@Wvv&$$$$$$$$$*<   "[email protected]`  .8$$$Munxrjjfjjjfffffff\..\fffft<.   ,/jj( 'frrrrrrrxxrrxrrxxxrr    //
//    rrxxxxxxxxxxxxxxxxxx/ ./rrjf`  .}r)..{jjjf`  '/ffffffjrxnc$$$$$$$$$#   .1jfffftffftffff(   ;[email protected]%*#[email protected]|   .1ffjfftfffjrxnvz   ;$$$$$cuxxrjjjfjfjjjjjf\../jffjjjt:   .lf| 'frrrrrrrxxrxrrxxxxrr    //
//    rrrrrrrxrxxxxxxxxxrx~ `jrjjj\'  .[' -jfjffl   )ffffjjrxnvB$$$$$$$$$&~   '1ftffftfttttf\`  "%[email protected]%&@$$$$$$$$$Mxri   '{fffffffjjrxnr`  "%$$$$$Bvnxrrjjjjjjjjjjf\../jfjjjjjj|^   'i 'frrrrrrrxxrxxrxxxxrx    //
//    jjrxxrrrrrrxxxxxxxxr^ irrrjjf(.    >jjjjjj{   ifffjjrxnu%$$$$$$$$$$cn?.  .:|ffftf/t/\+. .I%[email protected]%[email protected]_.  .:\ffffffjjr]' [email protected]$$$$$$$Bvxxrrjjjffjfjjj\..\fjjjfjjfjf['    'jrrrrxrrxxxxxxrxxxxx    //
//    jrrrrrrrxxxxxrrrrj|~  :1/rjjrj1.  ;rrjjjt1,   '](jrrxnu%$$$$$$$$$$Wnxrfi'   `;~]}-i". ';/x*[email protected]%8$$$$$$$$$$$#nrjft\!'   `;+]}]>,. '!z$$$$$$$$$$%unxrrjjfffjjt)l  l1/jjjjjjjjjj~.  'jxrrrrxxxxxxxxxxxrrr    //
//    jrrrxrxrrxrrrrjfj1,,,,,,!jrrrrj}"~jrrjjj+,,,,,,,,txxnv%$$$$$$$$$$$vnxrjff|<,`''.'`^,<(tfjrn%@BB%8$$$$$$$$$$$Bnxrjftttt(~,`''.'`^:+/[email protected]$$$$$$$$$$Bvnxrrjjffff-,,,,,,_jrjjrjrjrrrf;`:rrrrrrxxxxxxxxxxrxrr    //
//    jrrrrrrrrrrrrrrrrrrrxxrrrrrrrrrrrrrrrjfjjrrrrrrjrxnnv%$$$$$$$$$$$#nxrjffftfftttftttt/ttfjrxcBB%8$$$$$$$$$$$$znrrjftffffffffftffffjjrxu#$$$$$$$$$$$Bvnxrrfjjfjjjfjfjjjjjrjrrrjjrrrjrrrrrrrrrxxxrxxxxrrrrr    //
//    jrrrrrrrrrrrrrxxxxrxrrrrrrrrrrjjjjjrrrjjjjjjjjjrrxnvB$$$$$$$$$$$&uxrjfffftfttttfftftttffjrxu#%8$$$$$$$$$$$$Wnnxrrjfffffjfffffffffjjrxnu&$$$$$$$$$$$Bcnnxrrjjjjfffffjjjjjjrrrrjxrrrrrrrrrrxxxxrxxxxrxxrrj    //
//    jrrrrrrrrrrrrrxxrrrxrrrxrrrrrjjjjjjjjjjjjjjjrrrxnnvB$$$$$$$$$$$BuxxrjftffffffffffffttftfjrxuvW$$$$$$$$$$$$%[email protected]rjjjrrrrxxxxxxxnnxxxxxxxrrrrr    //
//    fjjjrjrrrrrrrrrrxrxxrrrrrrrrrr[email protected][email protected]&zunxxrjffrjjjjffffjjffjjjxxnnvB$$$$$$$$$$$Bcunrxrjjjjjffjjjjjjrjjjrrrrxrxxxxxxnnxxxnxnnxrrxxx    //
//    jjjrjjrjjjjjrrrrrxxxxrxxxxxrr[email protected][email protected]%%zunxrrffjjjjjfffjffffjjjrrxnuvB$$$$$$$$$$$Bcunxrjjjjjjjjjfjjjjrrjjjrrxxxnnxrrxxxxxxxnxxxxrrx    //
//    jjjjjjjjrrrrrrrrrrxxxxxxxrrrxrrrjjrrxxxrxxxxxnuv%[email protected][email protected]%BBBcuxxrjjjfjjjjffffffjjjjrrrxnuvB$$$$$$$$$$$Bvunxrrrrjjjjjjjjjjrjjjjjjrrrrrrrrrxxxnnxxxxxxxxx    //
//    jjjffjrjrrxrrrxxxrrrrrrrrrrrrrrrrrrrxrrxrrxxnnu%[email protected][email protected]%[email protected]$BvunxxrjjjjjjffffjfjjjjjjrxxnucB$$$$$$$$$$$%vnxxxrrjjrjjjjjjjjjjrrrrrrrxxxxxxrxrxxnxxxxxxxx    //
//    jjjjjjjjjjrrrrxxxxrxxxxxxrrrrrrrrrrrrrrrrrrxnu8$$$$$$$$$$$Bvnxxjjjffttttttfffffffffjrrxnv%[email protected]%[email protected]$$$BvunxrjjjjjfffffjjjjjrrrrrxxnucB$$$$$$$$$$$%vnnxrrjjjjjjjrjrrrrxxxxxxxxxxxnnnxxxxnnxxxxxxx    //
//    [email protected][email protected]%[email protected]$$$$$%vunxrrjjjjjjfjjjjjjrrrrrxrxnucB$$$$$$$$$$$8vnnxxrrrjjjjrjrrxxxxxxxxxnnnnunnnnxnnxxnnxxxx    //
//    [email protected]fftttttffffffffjjjrrxnu&$$$$$$$$$$$B&%[email protected][email protected]$$$$$$$$$$$&vunxxrjrrrrrjrrxxnxxxxxnnnnnnnnnnnxnnxxxxxnx    //
//    rrjjjjrrrjjrjrrrrjrrrrjjjjjjjjjfjffjjjrrrxn#[email protected]&[email protected][email protected]$$$$$$$$$$$Wvunxrrrrrjjrrrrxxxnnnnnnnnnnnnnnnnnnnxxxxnx    //
//    rrjrrrrrrrrrrrrrrrrrrrjrrjrrrrjjjjjfjjrrxu*[email protected]%$$$$$$$$$$$&[email protected]$$$$$$$$$$$Muunxrrrrjjrjrrxxxnnnnnnnnnnunnnnnnnnnxxxxx    //
//    rrrrrrrrrrrrrrjrrxrrrrrrrrrrjjjjjjjjrxxnuz$$$$$$$$$$$$znxxrjjfffffffftftffjjjjjrrxxu#[email protected]@$$$$$$$$$$$Munxrrjjjrrjrxrxnxxxxxxnnnnnuvz$$$$$$$$$$$$#unnxrrrrjrrrrxxnxnnnnunxnuuunnnnnnxxxrxxx    //
//    [email protected]$$$$$$$$$$$#nxrrjjfffffffftttfffjjjrrrrxnz$$$$$$$$$$$$*unnnnuz$$$$$$$$$$$$#unxrjjfjjfjjjxxxxxrrxxnnnnnuv#$$$$$$$$$$$$zunxxrrjjrrrxxxxxxnnnunnnuuunnnnnnnxrxxxx    //
//    rrrxrrrrrrrrrrrrrrrr[email protected]$$$$$$$$$$$#unnxxxnu#[email protected]rrrxxxxnxnnnnununnnnnnnnxxxxxrr    //
//    rrxxxrrrrrrrrrrrrrrrrrrjjjrrrrrjrrxxnnv%$$$$$$$$$$$8unxrjffffjjffttttt///[email protected]xxxxxxxxnuv8$$$$$$$$$$$Bvnnxrrrrrrrxxxxxnnnnuuuuunxxxnnxrrxxxxr    //
//    [email protected]ftfffftttfjjjrnnu%$$$$$$$$$$$%unxxrrrrxnuu%$$$$$$$$$$$BvunnxrrrjjrjxxxxxxxxxxxxxxnnuvB$$$$$$$$$$$%uuxxxxrrxxxxxrxxxnnnnnnnnnxxnnxxxxxxxr    //
//    rrxxxxrrrrrjjrxrrrrrrrjjjjrrrrrrrxnuvM$$$$$$$$$$$$*unxrrjffjjjjjfftfffttfjjjrxnu&[email protected]$$$$$$$$$$$8vunnxxrrrrrrrxxxxxxrxrrrxxnnuz$$$$$$$$$$$$Wunnnrrrxxxxxxxxxxxnnnnnnnxxnnxxxxrxxx    //
//    xxxxrrrxrrrrrrrxrrrrjjjjrrrrrrrrxnuv*$$$$$$$$$$$$WunxrrrjjjjjjjfftffffftfjrrxnuM$$$$$$$$$$$$#uxrrjjjjjrxxuu*$$$$$$$$$$$$Wunnxx                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MOON is ERC721Creator {
    constructor() ERC721Creator("M O O N", "MOON") {}
}
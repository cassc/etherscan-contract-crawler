// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Saturn Saga Pills
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                           //
//                                                                                                                           //
//    olclllc:colll;;:c:;:ll::llccoc,,,,,,'',ld:';clc,'',ldlcoxxxdxxd:;,',cdxxd:;;';oc,'''''':do;;l:,'''''''''''''''''',:    //
//    oxxl:,,,,lxd:';c:''cl;.,xkoc;..........ckl:dkl...,cll:d0kdolc:oxxoccclccxx;..ld'..':c' ,ko'ld;.  ....'''..       .,    //
//    oOo,;:;,:ldd:;oo',lko;:lc;'.....  ......,,,d0d::c:'..'xk:.....c0kl,.. .:xd;..;ool;;:,.,ol:d0x,.  .',,;;;,'......  ,    //
//    dOdcc;',::ld::ko;:lkkl:'....................,'.......okd;...'cl:.....,d0kddllldo'..,:dxlllokx,.  ..'''''''....'.  ,    //
//    lkkc'..,cl;;ooxo,.'c;'................',,'..........:c'....,;,.....'oxoc:;;;ckk:;lxO0kolc.,xd,.                   ,    //
//    c:;;;coxd:,cdc,.............',;::cc:,,;cl:,'''''....,...'''.......;dl'.....cxkxkxolxxcl;..cdl;.     ..''''''..   .,    //
//    cloxxdxkdcc:,'...........'':loooddxxxdddxdolllc:,.................l:..;ooodookd;..,;,.:o:lddd;.     ,ddooooo;.   .,    //
//    ldxl:l:lOxc:;'..........',lxoccccloodxxxkkxdddl:,'................ll;;:x0kdoloc...,;'..cOo.:d;.    .:dllllol'     ,    //
//    ll;',';xOd:'..... .....,,lxl;;;;:clodxxxkkkxdoc;'.................';;:oOkoc::dOOxo:...'ld;.cd;.    'loooloxc.     ,    //
//    o:'';ck0x:'...........',:dl,,.....';clodxxO0xc;;'...................;do;....cxddkd,..',,...dx,.    .,,,,,,,.      ,    //
//    dxlcllodc'....',......,;cl;'...  .....,codddkd:'...................:c'.....,,.'lxc;,'.....;kd;.      ........     ,    //
//    x0xo:,''..:;','......',:l:,.....     ..':ooc:odc'.................;,........':l:..,......'oo:;.     'llcccll:.    ,    //
//    lxd,....:xkl,'.......';cl;'..  ..    ...,::;,,cdl,...............'........,;:,........'',llcc;.    .co;,;;ld;     ,    //
//    ll'...,dkl'..........,;lo;,...... .......'''.',:do;....................',,'.......':lddodoool;.    'dc,:clxl.     ,    //
//    l,.,:lddo;...........,;oo,'...................',;od;..................'........,:lk0Oooxxcldl;.    ,:....':'      ,    //
//    oxdllc,..............,;oo,'....................',;od:''.....................,;:oxxl;..'lc,;:c;.                  .,    //
//    cdxc,......;;........,;oo,'......................,;ld:''..................,:;,oOo,','.''..'cl,.     .,::::::,.   .,    //
//    ;;;.......cc.........,;lo;,......................',,ld:,'................cxl;:okxdl,.;c..,:,;;.     .';lxc,,.     ,    //
//    ;..,...,,;o:.........,;:l:,'............'''.''''''',;od:,,'............'lo:'. 'od;. .dxlddc,,;.       .ll.        ,    //
//    ,.cl,,cdccl;.........,,:oc;,'''..',;;:cclllllllcc:::::lo;,,,'..........''.. .';,...,lxo:lxl.,;.       ,o,         ,    //
//    ,,xkdxkdc:...........,,:dl,;::cldk0KXXNNNNNNWNNNXXK00koooc:;;,,'..................;lclxkd:.,l;.       ...        .,    //
//    :cl;ldkd'............,;;lddOKXXK00XNWWWWNX00KNWWWWWWWWNkdOddkdl:,'.......... .....:;,lkx,.':c;.     ....   ...   .,    //
//    c,.;;.,l;';'........',cd0NWWWWWWNK00KNWWWN0kkOKXWWWWWWWXxodx0WNKkl;''...... ... .co:ld:. ,ool;.     ,d:.  'ol.   .,    //
//    ;....,:xkxc'.......',oKWWWWWWWWWWWNX00KXWWWNK0kO0XNWWWWWKdddkXWWWNOl;'...........lo:c,..:oc,:;.    .lo.  .:d,    .,    //
//    ,..,,';oc'.........,dXWWWWWWWWWWWWWWWXK00XWWWNX0kk0KNWWWWNOddkNWWWWNk:'.........:ocdxccdl. .,;.    ;doc::cdc.    .,    //
//    ::oo:,:;..........':ONNNWWWWWWWWWWWWWWWNK00XNWWWX0OO0KNWWMNkdd0WWWWWWk;'...... 'dkoolc;dxc'.,;.    .,,,,,,,.     .,    //
//    cc;:okl..........'';ONXNWWWWWWWWWWWWWWWWWNX00KNWWWNX0kO0XNWKxdxXWWWWWKc''.......xo.  .:xOOocl;.      ........    .,    //
//    ,..;xx'...........'ckKXXNNWWWWWWWWWWWWWWWWWWXK0KNWWWWX0OOOKNOddOWWWWW0:''.......;l'.'cl:,lxc;;.     'llcccloc.   .,    //
//    :::cxd:;.........''l00OKXXNWWWWWWWWWWWWWWWWWWWNK00XNWWWXXNNWXkdxXWWNXOl,'.........,cxl;::ldcc;.    .co;,,;ld;    .,    //
//    c;;oxkx:'.........':ONKOO0XXNNWWWWWWWWWWWWWWWWWWNX00KNWWWWWWW0xdONX0KKl,'.......,cddc,:xOkocc;.    ,dc,cddo:.    .,    //
//    ccc;;od;..........',oKNX0OO00KXNWWWWWWWWWWWWWWWWWWWX00KXWWWWWXkodO0KXx;'......':cc,...,loo;.,;.    ,:...,:,.     .,    //
//    dko;...............,;o0XKKK00O0000KXNWWWWWWWWWWWWWWWWX0OO00KKKOddkXKd;''............ .:ll:..,;.                  .,    //
//    ;,ol...............',,:oOKXKKKKK00000KKKKKKKKKKKKKKKKK00OO0KXNXkoxkl,'.........',....:l:::..,;.     .;:'. .,;.   .,    //
//    :cl,..'..............',,:ldOKXXXKKKKKXXKKKKKKKKKKKKKKKKKKKKKXNKxdc,,'.........,c'..'coc.'c,.,;.     :xxd:.,d:.   .,    //
//    olc;,;,...............'',,,;coxk0KKXXXXXXXKKKKKKKKKXXXKK0OOxdol:ll''..........ol..;loc',cllll;.    .ol,cdooo'    .,    //
//    oxxOk,....................',,;,;oolodddxxxkkkkkxxxdddolc:;;,,,;;cl,'..........okoxOkdccdOkxdl;.    ;l, .;lo;.    .,    //
//    ;.,x:... .'.................',;;coc;;;,,,,,,',,,'''',,,,''''..',;l;'..........;O0kkkkdc:cccll;.    ..    ...     .,    //
//    c:lOo;;:::,...................';,:l:;;,'.......................',::'.........,oo;.:xOkl::;:dx;.                  .,    //
//    ;''ckdlc,......................,;,cd:,,.........................'::'.........oo..ldl,.... .dx;.       .....      .,    //
//    ,.'do. .,'......................,;;ld:,'........................':c'.......'c:..c:...... .;lc;.      .:ccc'      .,    //
//    cokOkdlc'............ ...........,;;ld:,'.......................':c'......,;'..;,.. .....:lc:;.      ......      .,    //
//    ol,;lc,.''..,...,'................,,;ld:'.......................':c'.....'..........;llool:,;;.                  .,    //
//    ;.....';'.,dc.,ol'','..............',,coc'.... ............ ....':c'.................;:,..clc;.      ...'..      .,    //
//    ,..:lc:'..dK0xxkxdl,................',,:l:,....  ... ..........''cc'....................:do;;;.    .'''...',.    .,    //
//    :ldl,,c;.:OKk:':ko....................,,;cc,....  .............',c:...................:ol;..:;.   .;, .,''..;.   .,    //
//    od:':dO0xxOd,.,oo:;'...................',,co:'.................';c,...  .......',...:do;''':l;.   .;..:c,'. ;,   .,    //
//    dxoodkOxc:;..:kkoc:;,....'...............',:ol;...............'';;...  .......;o,.;dd:;;',dxl;.    ';......',.   .,    //
//    :,,col;.....o0KOxolkx' .,'................'',col;............'';;'..  ........lOooOd:ldclkd,,;.     .''''''..    .,    //
//    ::c:'.....;lk0xc:loo;..;;.............. .....',cll:'.......'',:c,.......'.....,cox0kclxOKO:';;.        ..        .,    //
//    lc'.......''ox'..:o'..::.......................'';lll:;,,,,;:cc,......;;......',''o0xdxO0K0xl;.                  .,    //
//    :.........;d0klloo, .cc.....::....',...............';::::::::;'.....cl;,;,'';;:xdd0Oo;,;odkOo;.                  .,    //
//    c;'.''':cok0x:.'colco:. ..'ll.  .:l'..''. ...............'........;xOo::,';odokKXKd,...lo':xl;.  .................,    //
//    oOOxoloc:;;lko.';lkd,. ..;c:.. .cko;,;'...........................ckkl,.':kKkxOKOc....,xo.:xl;. .',,,''...........,    //
//    loxxOOxccdoldo,;lc;. ..:dd;. . .;oxo,..''......... ..............'ll;'';okxlcd0k,...,'.cdoxd:;. .;;;,,'''....... .,    //
//    :;:lk0dcl::lccokl..';:lxx;.  ..;lxc.';c;... ....................,dx:;:okxc::ckKd;;cc;'..;xk;,;. .,,;;;,,;;;;;,,. .,    //
//    :;,'oxcoc.ckkdlxkdlclokk, .':loc:clllc:;'.'.,:;,;,,.'',;,'',;,;:cloodkxc;:odlddoodo;;:;ck0l.;;. .....'..''.....  .,    //
//    ;..,dl::.,:cxkxxxoloc:xOdodxo;.;:',,.....;lo;.........:;...':odlccokOo,'',colc::lxxoxkxold:.;;. .              . .;    //
//    :,,cocc;;:::cldodddo;,codddl;,;c:,,,,,,;:odc,,,;;,;,,:oc;;;cddoolccoo:;;;;;;;;;:cooddoc::lc::c;;;;;;;;;;;;;;;;;;;;:    //
//                                                                                                                           //
//                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Strn is ERC1155Creator {
    constructor() ERC1155Creator("Saturn Saga Pills", "Strn") {}
}
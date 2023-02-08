// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BeatHeadz Checks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0OkkxdoollccccccccccccclloodxkkO0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kdol:;,'........'',,,;;;,,,,,,'........',:coxO0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0dc'...';:lodkOO0KXXNNWWWWWWWWWWWNNXXKK0Ox:  ',...':dOKKKKKKKKKKKKKKKKKklo0K0KKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0o'..:dOKNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWk' .xNKOdc..'o0KKKKKKKKKKKKKKx' .xKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKc  .;:;;:cokXWWWWWWWWWWWWWWWWWWWWWWWWWWWWNd.   dWWWWWXo..:OKKKKKKKKKKKKd.  .xKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKko:.           'xNWWWWWWWWWWWWWWWWWWWWWWWWWXl..:. oWWWWWWWx. ;dOKKKKKKKK0l... .xKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKOo;.               .xWWWWWWWNNXXXKKKKKKKKKXXN0:  lk, oWWWWWWW0,   'ckKKKKKO:..dc 'kKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKkc.                 .,dkdlc:;,'''...........'''. ,:;;. cKNWWWWWx.     .:kKKk, .,c' ;OKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKk,                   .....',::ccccccc:::::ccc:.  'kK0c. ..';coo:.        .od. ,xdc. c0KKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKl              ,odoooodxxxdolc;,''............ .::;co; .ldl:,'..          ...,,cxl..dKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKc             ,OKKKKOdl;'.......''',,,,,,,,'  ,kK0ko;.  .;cokO0d.          'x0kl:. ,OKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKK:.,; .c.      ;00xc,.....',;;;;;;;;;;;;;;;. ..;OKKKKo. ......'cc.         .l0KKKd..oKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKK0llKO,oXk'     .:'...',;;;;;;;;;;;;;;;:;;'..,xx:;codo. .;;:;,'..         'oo:;coo' :0KKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKK0:.;kX0l.       ..';;;;;;;;;;;;;;;;;;;;,.  'kKK0kol;. .,;;;;;;;;,..     'kKK0kd:. 'xKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKK0:.:kK0o'.     .,::;;;;;;;;;;;;;;;;;,.. .co;;d0KKK0c..,:;;;;:;;;;:,.  ;c;;okOOkc..dKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKOclKO,lXO'     .;;;;;;;;;;;;;:;;;;,..  .lKK0o;:loo;..,;;;;;;;;;;,..  ,OK0dc:c:. .o0KKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKK0O, ,, .:.      .;;;;;;;;;;;;,,;,'. .cc,.cKKKK0xo;. .,;;;;;;;;;'...;o,'kKKKKKk:..dKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKK0kdc;'..  .....      .;;;;;;;;;;;;,......cK0Oo,:dO0K0o. .;;;;;;;;,'....oKKkc;cdO0x,  :k0KKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKK0xc,..,coxo':0KKK0Oko:'  .,;;;;;;;;;;:,. 'o,;OKKKOoc::;'..';;;;;;;;;,. 'l,;OKKKko:,'.    .,:d0KKKKKKKKKKKKK    //
//    KKKKKKKKKKKOl,..:x0NWWXc;KWWWWWWWWWXkc...;:;;;;;;;;;' .ox:;lxOKKKk;  .,:;;;;;;;;;;. .xk:;lxO0Oo. .'. .;c'.'cx0KKKKKKKKKK    //
//    KKKKKKKKKOl..,xXWWNxo0o,OWWWWWWWWWWWWNO; .,;;;;;;;;;;. .oOxc;;:l:. .,;;;;;;;;;;;;;'  'okdc;,'.  .,:;. .xXOc..;x0KKKKKKKK    //
//    KKKKKKKKx,.,xNWWWWx,,,'xWWWWWWWWWWWWWWWK; .''';;;;;;;'   .,;;'     .',;;;;;;;;;;;:'    ..''...',....,' .xWWKl..lOKKKKKKK    //
//    KKKKKKKx'.cXWWWWWO,oXkkNWWWWWWWWWWWWWWWWk. ''..';;;;;,. .::,'.     .......',,;;;;:' ...  .',;;::;'.  .  .xWWNk'.:OKKKKKK    //
//    KKKKKKO, :XWWWWWK;cXWWWWWWWWWWWWWWWWWWWWX; .;.  .,;;:;. .c;..     .,loc;,.......... .od,. .,;;;;;;'.     .kWWWO'.l0KKKKK    //
//    KKKKKKl 'OWWWWWWKkXWWWWWWWWWXKXWWWWWWWWWWx. ,,    .,;;.        ..,:lxkOOkkdoc'       .;:,.  .....,;'.     'OWWWo.'kKKKKK    //
//    KKKKKk' lWWWWWWWWWWWWWWWWNk:...;kNWWWWWWWNc .,. ', .',.  ..,;:ldxkkkkkkkkkkOd,.                   .'.     .,0WW0, cKKKKK    //
//    KKKKKo..kWWW0o:;:dKWWWWWNo.     .oNWWWWWWWx. .. ..     .:dxkOOkkkkkOOOkkkkkkxollccc::::;;,,''....'..     .occ0WNl ,OKKKK    //
//    KKKK0: ;KMWx.     .kWWWW0'       'OWWWWWWWO.    .,:c,  ,dddooollcc::;:okkkkkkx;';:;;;::;;:::::::lxkc.    .xW00WMk..dKKKK    //
//    KKKKO, cNM0,       ,0WWW0'       '0WWWWWWWx. ;l:;;;;;..,;:;.     'll'.ckkkkkkk,.oOkxxxl.   .:o:.'xOd.    .dWWWWW0' lKKKK    //
//    KKKKO, lNW0'       .OWWWWd.     .dNWWWWWWO,  :kk;.ckkOOO0KKd;...,xKx.,xOkkkkkOd''xKKKKKo,,;l00:.lkOx'    .dWWWWW0'.oKKKK    //
//    KK0K0; ;XMNo       :XWWWWNOl,',lONWWWNKkc.   cOkd,'o0KKKKKKKKOkO00o',xkkkkkkkkkd;'cx0KKKKKK0d;'lkkOx'    .kWWWWNo.'kKKKK    //
//    KKKKKx..cKWNx;. .'oXXdlxXWWWNNNWXo:;,'.     .oOkkxc,,cdO0KKKKK0xl;,cxkkkkkkxxxxkko:,;;:c:::;;cdkkkOd.    '0WXKk:..dKKKKK    //
//    KKKKKKx,..:ox00O0NWWd.  ,0WWWWWWK,          'dOkkkkxo:;;;:::::;;;lxkkoc;;,,,,;,,,;lxdllcccldkkkkkkOo.    cOc'..'ckKKKKKK    //
//    KKKKKKK0xl:. ;KWWWWW0ddxOXWWWWWWWx.         :kkkkkkkkkkkxdodddxkOkkl'',;:ccloxdlc;.,dkkOkkkkkkkkkkk:    .xc 'dk0KKKKKKKK    //
//    KKKKKKKKKKKx. oWWWWWWWWWWWKx0WWWWNc        'dOkkkkkkkkkkkkkkkkkkkOo..ldl::lool;;ll..dOkkkkkkkkkkkOd.    ok'.oK0KKKKKKKKK    //
//    KKKKKKKKKKK0; :XWx:kWWWWWWo ,KWWWWx.      .lkkkkkkkx::xOkkkkkkkkkkd,.,:;,:oddol;'',okkkkkxdxkkkkkx;    cXd..xKKKKKKKKKKK    //
//    KKKKKKKKKKKKl ,0Wl ,KWWWWWk..xWWWW0'     .lkkkkxdkk:..ckkkkkkkkkkkkxl:;;cxkkkkkdodkkkkkkl,,lkkkkk:.  .oXNl ,OKKKKKKKKKKK    //
//    KKKKKKKKKKKKd..kMx..OWWWWWX: cNWWWO'    'okkkkko,;:.;'.okkkkkkkkkkkkkkkOOkkkkkkxxxkkkOk:.:kOkkkk:. .:OWM0, c0KKKKKKKKKKK    //
//    KKKKKKKKKKKKk, cXO' dWWWWWWd..kX0x, ..;lxOkkkkkko:,';;,';xOkkkkkxdoodkkkkkkkl;;;;,,cc:,,lkkkkkx;..cdlcoo,.;kKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKx'.,;. ,x0KKOx;  .....:dkkkkkkkkkkkxdkkkkko,,:lol:;;;;;,,lxkkd;'cxkko....:xkkkkko'  ....,,,:oOKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKOoc:::'..'...,coo:..;xkkkkkkkd:;ol,:xkkkkkko:;;;:oxkOkxl;;;;,:dkkkkk:..:kkkkkxc..;lloxO0KKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKK0kxdxkO0KKK0x,..:dkkkxldx:..'dkkkkkkkkOOkkkOkkkkkkkxxxkkkkkkkOd,;xkkkxl..'d0KKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0d,..;okx:,;',c;cxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxc'..lOKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKK0kdc;;x0d;..'co,.',okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkko;..,oOKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKK0xc,. .  :0K0kl,.  ,oodkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxo:..  .:x0KKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKK0kc'...',;. .xKKKK0xc,..';cokkkkkkkkkkkkkkkkkkkkkkkkOOkxo:,.  .''.. .'lkKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKK0x;. .';;;;:,. ,OKKKKKK0ko;. ,xkkkkkkkkkkkkkkkkkkkkdoc:;'....  .;;::;,'. .:kKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKO:. .,;;;:;;;;,. ,kKKKKKKKKo..lkkkkkkkkkkkkkkkkkkkkx,  .;coxo' .,;;;;;;;;,. .lOKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKx' .,;::;;;;;;;;,. .ckKKK0KO, .:lodxxkkkkkkkOOkkkkkkxc. c00x:. .;;::;;;;;;:;'. ,kKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKx' .;;;;:;;;;;;;;:;'...,ldO0o.     ....'',,,,,,,,,,'......;,. .,;;;;;;;;;:;;;;,. 'kKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKO, .;;;,,,;;;;:;;;;:;;,.....'.        ';  ,clcccccclll' .:. .',;;;;;;;;;;;;,,;;:,. ;0KKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKo. ''..  .,;;;;;,;:;;;;;;;,'.         cc  .:odxxxxkkkd.  'c'.;;;;;;;,;;;;:'   ..'. .dKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKK0:   .'c:. ';;,.. .,;;;;;,'...        .l,    .,kXXXNNWk.   :l.'::;:,. .',;:. .:c.    cKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKK0:  ,d0Kx. .,. ..  ';,'....''.      ..'dc...   .oXWWWNl .,;,.  .',;'  ....,. .kKOo'  c0KKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKxco0KKKO,   .;xx' .. .,lxOKd.      :, ',,;;co;  ;OWWK, .l;    .. .. ,kd,.   ;0KKKOocxKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKd'.;x0K0:   ,x0KKKKl       :;      c0:   .oXx.  'o'   ;o'   l0K0d,.,xKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKOk0KKKKk;.cOKKKKK0:       ;;'xl. .okl'..  :c..,;'    .xO:.:OKKKK0kOKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0O0KKKKKK0;       ;:.'.,;...',;,,,;lc,.       cK0O0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO,       ,:   ..          ,:.        ;0KKKKKKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKKKKK    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BHZ is ERC721Creator {
    constructor() ERC721Creator("BeatHeadz Checks", "BHZ") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dolor Vi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMM    //
//    MMMMWXXXXXXXXXXXXXXXXK000000KKXXXKKKXXXXKK00KKKKKKKKXXXXXXXXXXXNNNNNNNNNNNNWNNXXNNWWNWWWWNNNNNNNNNWWNNNNXNNNWWNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXKOOKWMM    //
//    MMMMXO0KKXXXXXXXXXXXXXXKKOkkOKXXXXXXXXXXXKd;cxO0XXXXXXNXXXXXXXXNNNNNNNNNNNXKOdxOkOXNNNNNNNNNNNNNNNNNNXKXNNNNNNNNWWNNNNNNNNNNNNNNNNXXXXXXXXXKKK0xlo0WMM    //
//    MMMMXO0KKKXXXXXXXXXXXXXXXXKKKXXXXXXXXXXXXN0:...cOKXXXNNXXXNXNXO0XNNNNNNNNXd::lxdlxXNNNWWWWWWWWWXkxxoc;cONNNNNNNNNNNNNNNNNNNNNNXXXXXXXXKKKKKKKK00kx0WMM    //
//    MMMMXO000KKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNO' .'cdOKKKK0kkKXXKl,xXNNNNNNNx,';lllxKNNNNWNNNNNNNKc',;''lkKXXXNNNNNNNNNNNNNNNXXXXXXXXXXKKKKKKKKKKKKK0KWMM    //
//    MMMMX0KKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXd.   'cldxkxdldXXXl.'kNXXNNXx'..',,;d0XNNNNNNNNXNKc..'..lKNXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKXKKKKK0KWMM    //
//    MMMMX0KXKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXX0:   ..,ldkOOdcOXXd..,kXNXN0;......,cd0XXNXXXXXN0c.....;ONXXXXXXXXXXXXXXXXXXKKKKXXXXXXKKKKKKKXXXXXXKK0KWMM    //
//    MMMMXO0XKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'  ..;o0KKKO:cOKd.  .l0NKc........;xXNXNXXXXXO;.....'kNXXXXNNNNNXXXXXXXXXKKKXXXXXXXKKKKKKKKXXXXXXXKKKWMM    //
//    MMMMXO0KKKKXXKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKl..',',:lxXO,.;kx.  ..o0l....  ..;x0XXXXXXXXO,  .. .dXNXXXXNXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKXXXXXXXXKKWMM    //
//    MMMMXO0KKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXl..:ddc::lOx' .,o, ...;c....   .;xkkKXXXXXXO,     .lKNXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKXXXXXXXXXXXXXXXKKWMM    //
//    MMMMNO0KKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKk' .'',;,,dl.   ..  ......     .::,o0XXXXXO;     .;0NNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMN00KKKKKXXXXXXXKKKKKKXXXXXXXXXXXXXXXXX0dcox:.       ...       .':;.     .'..,lkKXXXK:      'dKXNXNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMN00KKKKKXXXXXXXKKKKKXXXXXXXXXXXXXXXXXXOocoOO:.        .       .','.   .... ..;xkkkx:.     .',cONXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0xdolkKXXXXXXKOKWMM    //
//    MMMMN00KKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXKKkdlcl:.       .....    ....    ....  .co:co,.     ....lKNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk:....lk0KKKXOxKWMM    //
//    MMMMN00KKKK0KKKKXXXXXXXXXXXXXXXXXXXXXXXXX0l'.. ...      ......      ..     .    ....co'      .''lKXXXXXXXXXXXXXXXXXXXXXXXXXXNNNXXKK0xc;'.':oddxxodKWMM    //
//    MMMMN00KKKK00KKKKKKXXXXXXXXXXXXXXXXXXXXXX0doxxl:.       .....       ......      ';'...       ..,kXXXXXXXXXXXXXXXXXXXXNNNXXXNNNXXXXK0kdddodkkxdoo:l0WMM    //
//    MMMMN00KKKKKKKKKKKKKXXXXXXXXXXXXXXXXK0OOOOOOkkxo,.      .....       ....'..      .;,.        ...oXXXXXNXXXXXXXXXXNNNXNNNXNXXNNXXXKXXK0KX0OKKKK0000XWMM    //
//    MMMMN0O0KKKKKKKKKKXXXXXXXXXXXXXXXXXXKOxolc;;;;,,..       ....        ...'..                     .;::lOXXXXXXXXXXXXNNNNNNNXXNNNXXOk0XXXXKKXXXXXXXXKXWMM    //
//    MMMMN0O0KKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXX0d;,,,''..       ....        ...'..                     ...,ckXXXXXXXXXXXXXNXXXXNXXNXN0o::xXXXXKXXXXXXXXXKXWMM    //
//    MMMMW0O0K0kOXXXXXXXXXXXXKXXXXXXXXXXXXXXXX0o;,,,'..       ....        ...'..                     .:OKXXXXNXXXXXXXXXXXXXXXXXNXXXk;,:o0XXKXXXXXXXXXK0XWMM    //
//    MMMMW0OKK0dxKXXXXXXXXXXXKKXXXXXXXXXXXXXXXXKd,,,'..       ...         ......                  .  .lkO00KKXXXXXXXXXXXXXXNXXXXXNKd;:clOXKKXXXXXXXXXXKXWMM    //
//    MMMMW0OKKOooOXXXXXXXXXXXKKXXXXXXXXXXXXXXXKOd:,,'..        ...        ......                 ... ....'',;:ldxOKXXXXXXXXXXXXXXNXd;:cd0KKKXXXXXXXXXX0XWMM    //
//    MMMMW0OKKKxlkXXXXXXXXXXXKKXXXXX0O0KXXXXX0l,,;;,'..        ...        .....                  .'.       ....',:lxKXXXXXXXXXXXXXKd;;lk0KKKXXXXXXXXXXKXWMM    //
//    MMMMWK0KKKkcl0XXXXXXXXXX00KXXXXx,.:dO0OOxc..'','.          .           ...                 .;;..   ..':odxkOOkk0XXXXXXXXXXXXXk:,,oO0KKKXXXNNNNXXXKXWMM    //
//    MMMMWK0KKKOc;xXXXXXXXXXX00KXXXXKx'..lO0KKo'......                      ...                 .:;'..  ...',coxOKXXXXXXXXXXXXXXNKo,,;dKKKKXXXNNNNNNXXKXWMM    //
//    MMMMWK0KKK0l,dXXXXXXXXXKKKXXXXXXXO;..;xKXx'    ..                       .                  '::,..;;:cclodxxO0XXXXXXXXXXXXXXN0c,;;xKKKXXNNNNNNNNXXKXWMM    //
//    MMMMWKOKKKKd,lKXKXXXXKKKKKXXXXXXXX0c. .cko.                                                .,;,..lk0KXXXXXXXXXXXXXXXXXXXXXXNO:,;:kK0KKXXNNNNNNNXXKXWMM    //
//    MMMMWKO00KKk;;OXKKKXXKK0KKXXXXXXXXXKo.  ...                                                .','. .,cxOKXXXXXXXXXXXXXXXXXXXXXk;,;:dOO0XXXNNNNNNNXXKXWMM    //
//    MMMMWKO000KO:,dKXXXKXKK0KKXXXXXXXXXXKx,                                  ....             ...'..    ..,:xXXXXXNNXNXXXXXXXXXXk:;:cxO0KKXXNNNNNNNXXKXWMM    //
//    MMMMWKO0000Oc':kKXXXXXKKKKXXXXXXXXXXXKk'                     .....       .;;,''....     .....''..,;;clox0XXXXXXXXNXXXXXXXXXXkl::cxOOKXXXXNNNNNXXXKXWMM    //
//    MMMMWKO0000xc;;lkkxxk0KXXXXXXXXXXXXXXX0c.      .,:::ccllllc:cokkxdl:.    .,::;;;,'',........''',cOKXXXXXXXXXXXXNNNNXXXXXXNXOkOOdlx0KXXXXXXNXXXXXXKXWMM    //
//    MMMMWKO000Odc;,;clollkKXXXXXXXXXXXXXXXKx,    .:xKXXXKKKKKK0KKKXXXXNXk' .',ldxkOOkkkxdlcc;'..''..;dKKKXXXKKKXXXXNNNXNXXXXXKxlx0KOdk0KXXXXXXXXXXXXXKXWMM    //
//    MMMMWKOKKKK0Ol':kKKKKKXXXXXXXXXXXXXXXKKOl.  'o0XXXXXXXXKXXXXXXXXXXXXNk;:oxKXXXNNNNNNXXKKOkdoo:'',:xKXKKK000K0KKXXNXXXXXKx:,,:xOock0OOKXXXXXXXXXXXKXWMM    //
//    MMMMWKOKKKKKKk;;xKXXXXXXXXXXXXXXXXXXXKK0Oc. c0XXXXXXKK0OO0KXXXXXXXXXN0:;kXNNNNNXXXXXXXKXXXXXXKOo;'ckOxxdxkO00KXXXNXXXNKo',;,,;:'.,cd0XXXXXXXXXXXXKXWMM    //
//    MMMMWKOKKKKKKk:,cOXXXXXXXXXXXXXXXXXXXKKK0x' ;OXXKOkxdc,''',;:cclxKXXN0::0X0OkkkO0KXXXXXXXXXXXXXKd;,,;coOKXXNXXXXXXXXXXO,':c;.... .xXXXXXXXXXXXXXXKXWMM    //
//    MMMMWKO0KKKKK0l,,dKXXXXXXXXXXXXXXXXXXKKKK0: .dKXkoxkkd;.        .l0XXKdxXOc......':dkOO0KXNNNNXXOl,,cx0XXXXXXXXXXXXXXX0:'cc;.....lKXXXXXXXXXXXXXKKKWMM    //
//    MMMMWKO000KK0xl;'l0XKKXKKXXXXXXXXXXXXKKKKKd. ,xKK00000Oo,.      .:OXXXOOXXko;.      ....,lk0XNNN0c,cxKXXXXXXXXXXXXXXXXXx::c;....:0NXXXXXXXXXXXXKK0KWMM    //
//    MMMMWKO000KK0l,;,:oOKKXXKKKKXXXXXXXXXKKKKXO, .,oOXKO0KKK0xoolccldOXXXKodKXXX0o,.         .l0XNNNO:,xKXXXXXXXXXXXXXXXXXX0l::,.',:OXXXXXXXXXXXXXKKK0KWMM    //
//    MMMMWKO0KKKKK0xc,;o0KKXXKKKKKKXXKKKXXKKKKK0:. .';okO0KKKKXXXNNXXXXXXXO,.xXXXXXKko;...   .:ONNNNk:;xKXXXXXXXXXXXXXXXXXXXKo;,. .,oKXXXXXXXXXXXXXKKKKKWMM    //
//    MMMMWKO0KKKKKKKo':OXKKKKKKKKKKKKKKKKKKKKKKKx.  ...;l:;,,;clodxxkxdol;.. ,xKXXXXXXKOxdolox0XNNNk,:OXXXXXXXXXXXXXXXXXXXXXKl;'  .'oKXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMWKO0KKKKKKKd',kXKKKKKKKKKKKKKKKKKKKKKKKKl.    ..          ...       .'okO0XXXXXXXXXXXXXK0d,;kXXXXXXXXXXXXXXXXXXXXXX0o;.  .'dXXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMWKO0KKKKKKKx,,xKKKKKKKKKKKKKKKKKKKKKKkkK0l.                           ..';lxk0KKK0OkOOkl'..oKXXXXXXXXXXXXXXXXXXXXXXOl,.  .,kXXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMWKO0KKKKKKKl.'l0KKKKKKKKKKKKKKKKKKKKKkdxOd.                             .....',,,...';,. .,xKXXXXXXXXXXXXXXXXXXXXXKOc'.  .;OXXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMWKO0KKKKKKKo..;kXKKKKKKKKKKKKKKKKKKKK0kodo.     .........                                .;kKXXXXXXXXXXXXXXXXXXXKkol;'.  .:0XXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMWKk000KKKKKd'.,oKKKKKKKKKKKKKKKKKKKKKKK0Oc.   ..............      ..........             .cOKXXXXXXXXXXXXXXXXXXKx:'.''.  .c0XXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMWKk000KKKK0l..':OKKKKKKKKKKKKKKKKKKKKKkxc. ....................................   ..     .l0KXXXXXXXXXXXXXXXXXXkl,..''. ..o0KXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMWKk00KKKKKk;...;d0KKKKKKKKKKKKKKKKKKOc'..   ...'clloooolcc:,,,,,'''''''....''.......    .'o0XXXXXXXXXXXXXXXXXX0dc,..''. .'lollx0XXXXXXXXXXXKKKXWMM    //
//    MMMMWKO00KKKK0x:..';;:okKKKKKKKKKKKKKKKXO:''.    ..'dKKKXKOxOK0OOOOOxxkxocoxdl;,;:,'''...   .;kKXXXXXXXXXXXXXXXXXkc:;....'. .,,.';d0XXXXXXXXXXKKKKKWMM    //
//    MMMMWKO0KKKKK00x:'',,,,:ok0KKKKKKKKKKKKKK00d.    ...,oxk0KOk0X00KXKKKKXX0O0XXKxlx0kd:'...   .c0XXXXXXXXXXXXXXXXXKc......... ',.,xKXXXXXXXXXXXKKKKKKWMM    //
//    MMMMW0k0KKKKKKK0kl,,,,lxOKKKKKKKKKKKKKKKKKKx.      .....',;;:c;:oxkkkOKKkdxOkkl;oOOOkl'.    .oKXXXXXXXXXXXXXXXXXO;. ...... .'..oKXXXXXXXXXXXXKKKKKXWMM    //
//    MMMMW0k0KKKKKKKKK0l,,,lOKKKKKKKKKKKKKKKKKKKk'    ...,lol;,,'.........',;,,''...........     'kXXXXXXXXXXXXXXXK0xc.  ............cOXXXXXXXXXXXKKKKKXWMM    //
//    MMMMW0k0KKKKKKKKKKx;'',xKKKKKKKKKKKKKKKKKKK0:    ...;kX0kO0kdoc:c:,'........  ...          .:0XXXXXXXXXXXXXX0dc'.   ....'....  ..:0XXXXXXXXXXKKKKKXWMM    //
//    MMMMW0k0KKKKKKKKKK0l'.'l0KKKKKKKKKKKKKKKKKKKd.   ...'dXkc::clxOk0KOxddddddol:,:lc:'.       .dKXXXXXXXXXXXXKOd;..    ..'....    ..;OXKXKXXXXXKKKKKKKWMM    //
//    MMMMW0k0K00KKKKKK0Ko'.'lOKKKKKKKKKKKKKKKKKKKO,    ...,l:.....,:lkKKXXXXXK0o::oO0xc,.....   ,OXXXXXXXXXXXXX0d:'...   .',.... ....;xKKKKKKXXKKKKKKKKKWMM    //
//    MMMMW0k00000KKKKK0Kd...lOKKKKKKKKKKKKKKKKKKKKo.    .............';cloxkOOxoldxo;'........  :0XKXXXXXXXXXXKKk:.....  .,;'..   .',cxKKKKKKKKKKKKKKKKXWMM    //
//    MMMMW0k000000000000x,..cO0K000KK0000KKKKKKKKKx.      ..................',,;;,'.........   .c0KKXXXXXXKKKKKx;.....  ..',,'.   ..,cOKKKKKKKKKKKKKKK0KWMM    //
//    MMMMWKk000000000000O:..:k00000000000000KKKKKKO;         .............................     .'o0KKKKXXKKKK0l.  ....  ..'',,.....',o0KKKKKKKKKKKKKKK0XWMM    //
//    MMMMW0kO0OOO0000000Oc',:x00000000000000KKKKK0d'            ........................       ...;dO0KKKKKKK0l.    .. ...'',,...,:coOKKKKKKKKKKKKKKKKKXWMM    //
//    MMMMW0kOOOOO0000000Ol,';d000000000000KKK0Oo:,;:cc'.             ................         .;;''',;coxO0KKKOc.  ... ...'''...'cldOKKKKKKKKKKKKKKKKKKKWMM    //
//    MMMMW0kkOO0000000000x;.,d000000000000kl:;,;cx000kl:;'.                                   ,xkxxooo:,.';coxOOl. ......'','...'lxOKKKKKKKKKKKKKKKKKK0KWMM    //
//    MMMMWKkkO000OOO00000Oc',d0000000Oxol;..;lk0KKKK0Ooloo:...                              ..:O00000KKOo;,'..',;'..'....''''...;dk0KKKKKKKKKKKKKKKKKK0KWMM    //
//    MMMMWKkkO0Oo,ck00000koclk0Okxolc;,;:cok0KKKKKKK00dlooc,.....                           'cx0000000000OOOxl;.........'''',,'';dO0KKKKKKKKKKKKKKKKKK0KWMM    //
//    MMMMWKkkO0k;.'d000OOxlcoxxl;,:lddxO00KKKKKKKKKK00xcloc,....',..           ............'cdO00000KKKK000000Oo:cl;......',,'..,dO0KKKKKKKKKKKKKKKKKK0KWMM    //
//    MMMMWKkkOOkl,..:ooc::'';cccokO0000000KKKKK00KKKK0xcclc;''...,;'..........';::::;;,'..;okO00KK0KKKKKKKKKKKK0kk0Odlldoc::,.. .ck00KKKKKK0KKKKKKKKKK0KWMM    //
//    MMMMWKkkkkOOo.  .......;cxO0000000000000000000000kllol;'.....',..';;;;;,,;::ccc:;,'.'ck00KKKKKKKKKKKKKKKKKKKKK00000000Okdl' .:dOK0KKKKK0KKKKKKKK00KWMM    //
//    MMMMW0kOkkko'     .;;',,cx00000000000000000000000Oddkxdl,.....',,',,;;;,;;::::;;,,'..cO00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0o',dolxO0000K0KKKKKKKK00KWMM    //
//    MMMMW0kOOOOo;;;'..cdoc;,:dO0000000000000000000000OddkOO0ko::;',ll:::;;;;:clcc:;;;:;''lO00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOlckOlcx0000000000KKKKK0KNMM    //
//    MMMMWKOOOO0Okkkdccxkxdl::dO00000000000000000000000kkO00000OOOxxxkxdxdl:::oxxdl:clll:;d0000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00kxO0xlx00000000000000K0KWMM    //
//    MMMMWKOOOOOOOOOOxdkOOkoclxO0000000000000000000000OO0000000000000000OOkxxdxOOkxlcokkdox00000000000000000000000000000000KK0000000OxkOOO0000000000000KNMM    //
//    MMMMW0O0OOOOOOOOOOOO0OxdxkO000000000000000000000000000000000000000000OOO00000kxodkOdldOOOOOOOO00OOkxxdddollc:;;;;,,,;::cccllllll:::;:cllllodddxxxxONMM    //
//    MMMMW0k0OOOOOOOOOOOOOOOOOOOO000000000000000OOOkkkkkkkkkxdoooooddxxkkOkkkOOOOOkxoodkdcokOkxdlc:::;'......                           ....''',;,'',,,dNMM    //
//    MMMMW0kkkkkkkkkkkxxxxxxxddddxddxkkxxxxdddoolcc::ccllc::;;,,,,,,;:clllloddddddoc:cldolccl:,,'...             ........',,,,'..',;;;;;,,'''...'',;;,;dNMM    //
//    MMMMW0xxxdddolc::;;;,'.........',''''...............................''',,,,,,,'',,;;;,,'''',,''''''''''''',;;:ccclodddxkkkddxkOOOOkkkkxxxdooodxxkk0WMM    //
//    MMMMWXKK00OOkkkxxxxxxddddddddddddddddddddddddddddxddxxxxxddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkOO000000KKKKKXXXXXXXXXXXXXXXXXXXXKKK000OO0Ok    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNK0kxddl:,    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DLRV is ERC721Creator {
    constructor() ERC721Creator("Dolor Vi", "DLRV") {}
}
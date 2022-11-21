// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by Kipz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//           ....        ..............................          .......................      ..................                  //
//          ..''...;dxdolc;.  .cxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddc.  .;ldxxxxxxxdollllllllllloool:.  ,odxkxddddkkkkkkkx:.          //
//          ';;:c,.o000KKKKOc..ckOOOOOkkkkkkkkkkxxxxxkkkkOOOxxddl' .:xkkkkOOO0OkxdxxxxxddddxkOkko' 'okkkxxxdddkO00OOOOd.          //
//          .;;:l,.;kKXKKKKK0c. ..,;::;;,,,,,,,,,,,,,,,'..,cc;;;'. .clllc;,,,,,,,,,,;;;;;;;;;;;,,,:dOOxc'.''.',;:lkkkkx,          //
//          .;:c:'  .,:::cxOOd'  'oOOkkkxxddooddxkkxdddoc. 'c:;;...':c:'..';;:c::cccccccccccllldxkOOxc'.  .....  .;odkk;          //
//          .,;,,.  ..'.  .okkxl,';::cclllcccclldkkxdddxo' ;olc,. .,lo;. .;looddoooooooooollllol::;,..',;::cccc:. ':clo,          //
//          .,,,,. .;c:;'. ,x00K0Oxoc:,..........lOOOkOk:..cll:. .,col,    .,:::;'......''.......   .colllccllol,.,ol::.          //
//          .,,,,. .::;;;. .,xKKKKK0Okxd:..    .,dOO0Ox:..clc;. .cddxo' .':lxO0Okdl:. .cxxdl'       ..,'''..,::;. .:do;.          //
//          ';,,;' .;::cc;.. .;ok0000Oxdol:,.. .;lllc,. 'oooc. ,odoodc..,oolllcldxkko'.l00K0c   .;cc:;'.....',,,.  ....           //
//          ';,;;'. .;clolcc,.  .';;:::lxkOOkxoc:;'.   .d000d..o0Okkx:. .,'.','..,ldxl..lddo'  ,xKKXK0xl:;;;;;;,. .cdl'.          //
//          .;,;:;,'...':llx0o.    ..,,',lk000KKK0kdc,..cddo,. .:::;'.  .,lx0KO;  ;O00:.okkl. .cddxdl;,'....'''.. ,k00d.          //
//          .;;:cldkxo;..,okK0c. .,dOKKk:..;codxkOOOOx;  ..',;;.     .'cdOOOkko.  ,x0O:.xKKx,;xkxc..',,'''''''.   ;O00k,          //
//          ..,,,cxOkdl:..ck0Kk:,lOXK0Oxc.   ..',,,,,..  .codxd;.  .,okOOkxl;..  .ldxo..oxkkkOKKd..,loll:;,,,;,.  'dO0O;          //
//            ....,xkoll'.:kO0000KKK0d;'.';cloolllcc:;.  ;oddo,. ..ckOOOxc..   .:oxxd;.,dddoodxd, ..''''',;;;;;,. 'cdOO:          //
//          'lc:;..lxooo,.:kkkk0KKKk:..:okOOOkxdddoooo:. .:ooo;. .,oOkOx;    .:oxxxd;..ldddxdddc.  .:l;.  .:lll:. 'clokc.         //
//         .lOdll,.:dood;.:kxxOKKKk'.,odxxkdl:,,,,,,;;'..,dKKK0o'. 'x0K0c.  .:kxxxo,..oxxddddddc. .lk0O;  'looo:. 'loox:.         //
//          :kdol,.,llol'.cxxx0K0d, .cxxxd:..,lddddooooodxxxooll:.  .d0K0c.  :kkkx;  ;kOkkdolc;.  'lddl..,looooc..;oood;.         //
//          'dxol' .....  .,,;:;,.  .:xxdl' .cOOkxolcccccccc;,,;,.   'xKKKd' 'dOkkc. ..'''...    .;lod; 'xOxdooollooodd;          //
//          'odool;'',''''''',,,,''';dkdolc' ..'''...............   .;kKKKKo..lOkOkdl:;;;:ccccc::loooo:.,k00Oxooooooooo,          //
//          'ddxO0Odooooddddk0KK0xodkkkdodOd. .'cllccccccllllccclllok00KKKKo. 'dkkkO0000kkO0KXK0kxxdddx:.l000Okddolcc::.          //
//          'oxk0K0Oxddoooodx0KKOoloxxxdxkx:. .ckkxxxkkkkkkOkOO00OOO0KXXK0o'   .:oxOO00KK0kkO0KK0kxO00Ol..okkkxo::;,,,,.          //
//          ..,;;::;;;,,,'''',;;'..'''''''..   .',;;;;;;;;;::::ccc:ccclc:'.      ..',,;:::;;,;::;,;:::,.  .......... .            //
//          .....  .:oddolc:;,,,,',;,,,,;,,,,;,,,,,''..        ...........................'''...',,,,,,'..''''''''..,;'.          //
//         .;odxxc...cx0KKOxddxxxxO0OkO0K0OO00Okk000Oxoc;..  .';:lllcccoxkkOOxdddddxxdxxxxO00kdox0KKK0kdoooooooooocckK0:          //
//          'cdkKKkc'..,:llllloooxkkxdkOOkkO00kkO000Okxxkko,. .',cllloodOOOKKK0OkxxxxxddxkxOKKkook000Odollllllcc::;;cl:.          //
//           .;xKKOxdlc:;;,''.............',;;;:ldkkkxxkOOOxl,. .......','';::::;,,,,,'',,',;;,'.'''''.........                   //
//             .:dxxdoooxkkkkdlcllc::odol::;,,'.....,:okOOkxxxd:.       ...............''....',''.',,,;,'''''',,,,,'''..          //
//          .,,. ..,;:clddxkkkxdxxxod0K0kxxxxddolc:'. .':oxkO0K0xc,.   'looolldkOOOxodxkkkdodk00kdxOKKK0kxdddxkkkkxddkk;          //
//         .;odl'.    ....',;;;::c::cdxxdxkkxdddddddl;.. .'ck000000kc. .cooollccdxxdc:coool::ldxdlloddddlc:;;:clllcccc:.          //
//          'clo:.  ......            ....';;:coddooolc;'.  .cx000000kc........................................''''''.            //
//          'cll:. .:olllc:::::::::;;::,...   ..',:oolcllc'.  .ck000000kc.     'codl:'.   .'''.. .':cloooloxxolxOOkdoo;.          //
//         .;dddc.  'codddoooollodddxOKx:;:::,'.  .':llloddl'.  .lxO00000k:.   ;kKKK0kl.  .;;:c'  .,cloooodkOxdk00kdooc.          //
//         .:xxxl.   ..',,,;;;;;:cllooddolcloddc,.. ..:clddddc.  ..'o000000d,. .,xKKOkkc. 'cccdd,.  ......',;;:x00xoooc'          //
//         .:xxxl. .';,..      ..........'',;col::;.. .':ldddxo;.   .;dOOkxdo:.  ,k0kkkl. .:ccxKx,'.......     .ckxoddd,          //
//         .;xxxl. .lllo:.    .:loolcc::;,'. ..,::cc;.  .;looollc,'.  .;loloddc. .lkxxd:.  .'cO0o;;;;;:llc:,'.  .,odxkx;          //
//          ,oddc. .clloo'    .lkkxxdddddddl:.. .;lool,. .':loooxkOkl,. .,;cll,. .oxdo:;:'.  .;;,',;;;lolllodl;.. 'oxkd,          //
//          'ccc;. .loloo,     .cdxxddddddddol;. .;dxxxc.  .;odddkOOOOdc,.....   .colcccll:;,...  ....;ccccldddoc;..',..          //
//          ,lcc;. .colll'   .'...';:cloddddddxl. .,oxkxo'.  .;loloooooool:,....  ..';coddxkkd:::,..   ..';ldxxxxxo;.             //
//          ,lll:. .:lclc.  .okd;.  .....';coxxxo'  'lxxdo:.   .';::clllccllllc:;,'.. ..,coddl:::::;;,.   ..:oxxxxkkc.            //
//          ,lloc. .colol. .l0Okl. ,ddl:,....:dxxo,. .:dxddo:..   ...',;;clooooodddol:;'....';ldolcclol:..   .:dxxxxxc.           //
//          ,lldl. .ldddl. .dKOkl. ;kkxxxoc,..,odxd;. .'lddddl;'.       ..';:codxkOOkkkkxdc,. .,:loloddxo:.   .,oxxxxxc.          //
//          ;dddl. .cdxd:. 'kKOkl. c0Okkkxxd:. ,odddc'. .,ldollc,.   .';'.   ..',:ok0KKKKKKKkl'. .,lxxxxxko'    .lxxkOk;          //
//          ;dddl. .cxkx:. :0K0ko,,xKK0Okkxxx; .;oxxxxl'. .';::c;.  .:kOx,  ....   .':dOKKKKKK0o'. .,okkkk0O:.   .:xkOOl.         //
//         .;dddc. .lxkkc..lKKKOkkkOko;',lxkOd' .,oxxxkxl;..  ..    .cddo, .ldddlc:;'...:d0KKKKKOl.  .:x0KKK0o.   .'lk0o.         //
//         .;ddo;. ,dkO0l. ;OXKKOOko,... .lOOOd;. .;cdxkOkxo:;'.    .coo;. .cxxkOO0K0kd:..,oO0000Kk;.  'dKKK00x;.   ..,.          //
//         .;do:'. ;kO00l. .,oxxxl,',coc. ,x0OOOxc.  .';lxkkdoo:.   ;xkd'   .,lx0KKK00OOx:..'okOO00Ol.  .:kOkkkxc'.               //
//          ,ol:,. ,O0OKd.    ....,xOOkx:..;dOO00Ol.    .;xOxddl.  .:dd:. .':;'.,coxO00OOOd,..;d00000x;.  .cddoolc:;..            //
//          ,llc,. 'k0OOOo;....  .;lllc:'.  .',;;,..     .okxxxd'  .:xxc. .:xkxl;...':oxkkkx;. .lk0KKK0o.  .'colldxkko;.          //
//          ,lll:. .dKOxkkkxxxxdolllcc:;;;:clccccccccccccoxxxxxo.   :kOd.  .lxdxkkoc,...,ldxxc. .'lkOO00kc.  .':dkkk0K0c.         //
//          ,olcc'  :00OkkkkO0KK0OOkkxdlllodxkkkkkOOkxxxdxxxxxxo.   'x0Oc.  .:oxkkkkxxo;..,okOd;. .,okOO0Oo,..  .,:ldxkc.         //
//          ':::c,  .:odolllodxxddddddlccclllloddxxxdllloooolc:,.   .lOOx:.   .';:cllll;.  ;xOOOx:...:dkkdlll:;'.   ....          //
//          '::ld:.    ......................................       .:xxxd;.  ..'',,''....'cdkOO0Odc;..,:lloodkOkdoc:;..          //
//          ,ccoxdc;;;;;:::ccccccllcc,. .':cccc:::cclccccc::;;,'''',;cllllc. .;oddddddddddddddxxkxdddo:'..,cdOKKKKKOxxd'          //
//          ,lldxxxkkxxxxxkkkxxxxxdllc' .dK000OOkOOOOOOkkkkxxxxddooooooool:. .;dxxxxxxxxxkkkkkkkOkkkOOOO:.  .';:cc:;,'..          //
//          ..',,,,,,,,,,,,,,,,,,,'...  .';:;;,,',,,,,,'''''''''...........   ..,,,,,,,,,,,,;;;;;;:::::,.                         //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KIPZED is ERC721Creator {
    constructor() ERC721Creator("Editions by Kipz", "KIPZED") {}
}
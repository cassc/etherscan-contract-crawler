// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dark Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ';clloooooooddddddddddddddddddddddddoodddddddddddddddddddddddooooooooooolllllcccc:::::::::;;;;,,,'..    //
//    :okkkOOOO000000KKK00000000000000000000000000KKK000000000000000OOOOOOOOOOOOOOkkkxxxxxxxxxdddoollllc;'    //
//    :dkOOOOOO0000000KK000000000KKKKK00KKKKKKKKKKKKKK000000000000000000OO00000000OOOOkkkkkkkkkxxxddddol:,    //
//    cdOO00000000000000KKKKKKKKKKKKKKKKKKKKKKKKXKKKKK00000KK000000000000000000O00OOOOOOkkkkkkkkxxxxdddoc;    //
//    lxO0000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK000KKKK00000000000000000OOOOOOOkkkkkkkkxxxxxxxddol:    //
//    lxO00000O0000KK00KKKK0000000000KKKKKKKKKKKKKKKKXK000KKKKKKKKK0OOOOO000OkOOkOOOOOkkkkkkkkxxxxxxxdddl:    //
//    cxO000KK0000KKKKKKKKKKK00KKKKKKKKKKKKKKKKKKKKXXXKKKKKKKKKKK00000OO000OkkOOkOOOOOOOkkkkkkxxxxxxxxxdl:    //
//    cxOxc;;:cloxO0KKKKKKKKKKKKKKKKKKKK000KKXXXXXXXXXKKKKKKKKKKKK000KK00OOOOOOOOOOO0OOOOkOOkxdlc:;,;cddl:    //
//    cxk,        .';cdk0KKKKKKKKKKKKKKKKKKKKXKKKXXXXXKKKKKKKKKKKK0000000OOOO000OOOO00Okdl:,'..      .ldl:    //
//    cxk,             .';ldOKKKKXXKXKKKKKKKKXXXXXXXXXKKKKKKKKXKKKKK00K0000000000K0ko:,.             .cdo:    //
//    cxOl..                .,cdOKXXXKKKKKKKKKKKXXXXXXKKKKKKKKXXKKKKKKKK0000000ko:'.                ..lxo:    //
//    cx0x;...       .....      .,cx0XXKKKKXXXXXXXXXXXKKKKKKKKXXXKKKKKKKKK0ko:'.                   ..;ddo:    //
//    lxOOo'...        ........     .:okKKKXXXXXXXXXX0k0XXXKKKXXXXKKKKK0xc,.         ....        ...'lxdl:    //
//    lxO0Ol'...        ............   .,oOKXXXXXXXK0OkOOOO0KKXKKKKK0x:.      .........         ...'lxxdo:    //
//    lxOO0Ol'..         ........''...    .ckKXXXKOkkkkxdxkxkO0KKKOo'   ..............         ...'lxxxdo:    //
//    lxO0O0Oo,....       .....',,,,,'..    .lkkxdxkO0Oxox0Okxdddl'  ...............          ...'lkxxxdl:    //
//    lxO00000x;...        ....''',,;;,,.....'',:ldxdoolcloool:;;'.........''......          ...,okkxxxdl:    //
//    lxOOOOO00Ol'..         ..''',,,,,,'.......,:;,;cllccc;'..'........','''.....           .'cxkkxxxddl:    //
//    lxOO0000000xc'           ...........     ..'':d00Okkkdc,'..       .........          .,lxOOkkxxxddl:    //
//    lxO0000000000ko:;,...............        .';codkOkkkxdoc,..                  ....',:cdOOOOOkkxxxxdl:    //
//    lxO00000000000000Oxoc;,'......          ..,clc,,lxkd,.,::..                ..',:ldkOOOOOOOOkkxxxxdlc    //
//    lxO000000000Okoc;'..    .....   .... .....;:c:..:dxl'..,'....          ..      ...';:oxOOOOkkxxxddlc    //
//    lxO000000Oxc,.     ... ....'.   .. .,'.. .;,,:lloddl;,,.... ..        .''..  ..  ......;lxkkxxxxdolc    //
//    lxO000Oxc,. ...   ''. ... ..''.....','.   ..'clccll:;;,'..   .........'.....   ..  .... ..;lxxxxdolc    //
//    lkO0Oxl,...;:.  .;'  .,'    .',,'....   ......,,..'.....      ....''...    .'.  .'.  .,..  .,lxddol:    //
//    lkO0k:...;l;.  ,:.  .:'    ..  ..       .......,'',,........   ...    .     .;.  .'.  .:;....'oxdol:    //
//    lxO00x,.,dd, .c:.  .c,   ...          .......................          ..    ,:.  .,.  .lc...:dddol:    //
//    lxO000d'.':llxl.  .o:   .;,          .'....,,,'.    .....'''..         .,'   .lc   .:;,;,...coooool:    //
//    lxOOOO0kc...':c;,;oxc..'lko'       ..''....,:,.     .,;,..',''..       ;do;..,oxc,';:,.   .lddooolc:    //
//    lxkOOOOOOxc,....,;clllcllcllc;:::;;,.....  ..         .. ..''',;;;,'',coollc:ccc::,..  .';lddoooolc:    //
//    ldkkOOOOOOOkdl;'.........  ...'''..  .... ..           ..................  ......  .';:lddddoooollc:    //
//    ldkOOOOOOOOOOko:;;,.....             ..........      ....'....             ..   .'''cdxdddoooooollc:    //
//    cdxkOOOOOOOOOklcoxxdlc,.  .........   .......'','...','......      ..'..   ...:ccoc,:ddddoooooolllc:    //
//    coxkkkkkkOOOOkxxkkkkOd,..  ,;.   .. ...........''.....'......    ..   .'.....;dxxddlcloooooooolllcc;    //
//    coxxxkkkkkkkxxkOOkkkl;:lo'.:,     .  ........  .               ..'.    ,;.'::::oddddoooooooolllccc:;    //
//    codxxxkkkkkkxkOkkkxl:oO00x;.'.......   ... .....    .....      ..''''.,,';oxxxl:ldddooooooolllllcc::    //
//    codxxxxxkkkkkkOkkkxdk0O0OOOo:,.','.........';::.  ..',''..........','';:oxxxxxxoccodoooooolllllccc:;    //
//    codddxxxxkkkkkOOkOOOOOOOOOOOOx;:xkdc..,llcclxkkl. .'loolccllc'.;ldx:.:kkxxddddddollooolllllllcccc::;    //
//    clodddxxxxxkkkkkkOOOOOOOOOOOOOlckOOk,.o0000kxxxx:.,lxxxxxkOOk:.lxxxl:dkxxddddddoooolllllllccccc:::;;    //
//    :loodddxxxxxkkkkkOOOOOOOOOOOOkooOOOOc'o00000OOkk:'cdkkkkkkOOOo'cxxxdloxxxddddddooooolllllccccc:::;;;    //
//    :lloddddxxxxxkkkkkOOOkOOOOOOOddkOOOOkco00000000k::dxOkkkOOOO0d:okxxxdloxddddddooooollllllccc::::;;;;    //
//    :cllooodddddxxxxxkkkkkkOOOOkxxkOOOOkOooO000000kxxddxkkkkkkkOOocdxxxxxdoodddddooooolllllcccc:::::;;;,    //
//    ;ccllloooooddxxdxxkkkkkkOkxxkOOOkkkkkdokkkkkkkkkkkxxxxxxxxxxklcxxxdddddoodoooolllccccccccc:::::;;;,,    //
//    ;:clllllllloooddddxxxxxxxxxkkxkkkxxxxodOOOOkkkOOOOOOOOkkkxxddl:lddooodddddoollllcccccccc:::::;;;;,,,    //
//    ;::cccclc::::clooooooddddxxxxxxxxxxxoldxxkkkkkkkkkkkkkkxxxddoolclolloooollllllcccccccc:::::;;;;,,,''    //
//    ,;;;::::;;;;;:cllllloooooodddddddddoloddxxdxxxxdddddddddooolllllllcccccccccccccc:;;;,;;,,,,,;,,,,'''    //
//    '',,,;;,',,,;;::cccccclllllloooooooodddxxxdddddddddddddddddooooooolllccccccccc::;,,,,,,,''''''''''..    //
//    ...''',,,,,,,;;;;:::::ccccccccccclloooooooooooooooooooooooooloolllllccc::::::::;;;,,,,,,,''''.......    //
//    ...........'''',,,;;;;;;::::::cccccccccllcccccccccccccccccccc:::::;;;;;;;;,,,,,,,''''''.............    //
//    ..................''',,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,'''....................................    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DAIA is ERC721Creator {
    constructor() ERC721Creator("Dark Art", "DAIA") {}
}
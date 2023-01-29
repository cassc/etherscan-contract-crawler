// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mark Wabbitz
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ..##...##...####...#####...##..##..........##...##...####...#####...#####...######..######..######..    //
//    ..###.###..##..##..##..##..##.##...........##...##..##..##..##..##..##..##....##......##.......##...    //
//    ..##.#.##..######..#####...####............##.#.##..######..#####...#####.....##......##......##....    //
//    ..##...##..##..##..##..##..##.##...........#######..##..##..##..##..##..##....##......##.....##.....    //
//    ..##...##..##..##..##..##..##..##...........##.##...##..##..#####...#####...######....##....######..    //
//    ....................................................................................................    //
//    OOOOOOOOOOOOOOOOOOOOOOOO00O0000000000000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000000    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000000000000000000000000000000000000OOOOOOOOOOOOOOKKKK000000    //
//    OOOOOOOkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddddddddddddddddddkKKKKKK0000    //
//    OOOOOOkxdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddkKKKKKKKK00    //
//    OOOOOOkxdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddkKKKKKKKKKK    //
//    OOOOOOOxdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxdddddddddddddddddddddkKXKKKKKKKK    //
//    OOOOOOOxdddddddddddddddddddddddddddddddddddddddddddddddddddoc:::;:::cclodddddddddddddddddkKXKKKKKKKK    //
//    OOOOOOOxdddddddddddddddddddddddddddddddddddddddddddddddddo:,...........';coddddddddddddddkKXXKKKKKKK    //
//    OOOOOOOxdddddddddddddddddddddddddddddddddddddddddddddddd:'..''.'''''''''..'cdddddddddddddkKXXXKKKKKK    //
//    OOOOOOOxddddddddddddddddddddddddddddddddddddddddddddddo;'.''',:cllllcc;'''.'cddddddddddddkKXXXXKKKKK    //
//    OOOOOOOxdddddddddddddddddddddddddddddddddddddddddddddo:'...'':dxdddddxdc'''.,ldddddddddddxKNXXXXKKKK    //
//    OOOOOOOxdddddddddddddddddddddddddddddddddddddddddddo:,''...''':dddddddxo;'''':dddddddddddxKXXXXXXKKK    //
//    OOOOOOOxdddddddddddddddddddddddddddddddddddddddddoc,..';,'....'lxdddddddc'''.;oddddddddddxKXXXXXXXKK    //
//    OOOOOOOxdddddddddddddddddddddddddddddddddddddddddoc,..;oc'.....cddddddddc'''.,lddddddddddxKNXXXXXXKK    //
//    OOOOOOOxdddddddddddddddddddddddddddddddddddddddddddo:'.''.....;oxdddddddc'''',lddddddddddxKNXXXXXXKK    //
//    OOOOOOOxdddddddddddddddddddddddddddddddddddddddddddddc';olccclddddddddddc,''',lddddddddddx0NXXXXXXKK    //
//    OOOOOOOxdddddddddddddddddddddddddddddddddddddddddddddo;.;oxddddddddddddo;'''',lddddddddddx0NXXXXXXKK    //
//    OOOOOOOxddddddddddddddddddddddddddddddddddddddddddddddl;.,lddddddddddddc,''',cdddddddddddx0NXXXXXXKK    //
//    OOOOOOOxdddddddddddddddddddddddddddddddddddddddddddxo:lo;'';:loddddolc;'''';lddddddddddddx0NXXXXXKKK    //
//    OOOOOOOxdddddddddddddddddddddddddddddddddddddddddddxl,lxdl;''',,;;,,''''',codddddddddddddx0NXXXXXKKK    //
//    OOOOOOOxdddddddddddddddddddddddddddddddddddddddddxxd:,lxdxdl:;,''''''',;codddddddddddddddx0XXXXXKKKK    //
//    OOOOOOOxdddddddddddddddddddddddddddddddddddddddddxxo,,oxddddddolcccclooddddddddddddddddddx0XXXXKKKKK    //
//    OOOOOOOxddddddddddddddddddoloddxxxdddddddddddddddddc':dddddddddddxxdddddddddddddddddddddddOXXKKKKKKK    //
//    OOOOOOOxddddddddddddddddo:'.',;::::cloddddddddddxdo:'cddddddddddddddddddddddddddddddddddddOKKKKKKKKK    //
//    OOOOOOOxddddddddddddddoc,............',:ldddddddxoc,'cddddddddddddddddddddddddddddddddddddOKKKKKKKK0    //
//    OOOOOOOxdddddddddddddl,'........',;;,'...':oddddxo:,'lxdddddddddddddddddddddddddddddddddddOKKKKKKK00    //
//    OOOOOOOxdddddddddddxo;''.....;llodxxdol:'...:oddxl;',oxddddddol::;;;,,,;:codddddddddddddddkKKKKK0000    //
//    OOOOOOOxddddddddddddl,'.....'lxdddxxxdxxdl;..'cdxc,.,oxddoc:;;:cloool:'...';coddddddddddddkKKK000000    //
//    OOOOOOOxddddddddddddc,'.....;dddddddddoc:::'...;oc,';ddl;;;codxxddddxd:....'',cdddddddddddk0K0000000    //
//    OOOOOOOxdddddddddddo;'.....'cddddddddl,..';;::'.:c,':l;,:odddddddddddxo;....'',codddddddddk0K0000000    //
//    OOOOOOOxdddddddddddl,......,lddddddddc'.'codxxo,;ll:,;cdxddddddddddddddo,....'',:oddddddddk000000000    //
//    OOOOOOOxddddddddddo:''.....;oddddddddo:,'.',;:::::c:;:::::::coddddddddddl,....'',:ddddddddk000000000    //
//    OOOOOOOxddddddddddl,''.....:ddddddl,'',;:c:;;,,,,,,'''.......,lddddddddddo;....'',:oddddddx000000000    //
//    OOOOOOOxddddddddddc,'.....'ldddddd;......cdddddddddddc'....''':dddddddddddo,....',,cddddddxO00000000    //
//    OOOOOOOxododdddddo;''.....;odddddd:......,lddddddddddl,...'',',ldddddddddddl'...''';ldddddxO00000000    //
//    OOOOOOOxooooooooo:'.....':oddddddd:......':ddddddddddd;...'''',cddddddddddddc'...'',cdddddxO00000000    //
//    OOOOOOOxooooooooo:....,:oddddddddo,......':odddddddddd:...'''',cdddddddddddddc'...'';lddddxO0000000O    //
//    OOOOOOOxoooooooooc;;:coddddddddddo'.....''cdddddddddddc....'''':ddddddddddddddc'....':ddddxO00000OOO    //
//    OOOOOOOxoooodddddddddddddddddddddl......''cdddddddddddl'...'''';oddddddddddddddo:'...'cdddxO0OOOOOOO    //
//    kkOOkOOxdooooodooooddddddddddddddo'.....',cdddddddddddo,....''',lddddddddddddddddoc;'.,lddxO0OOOOOOO    //
//    kkkkkkOxdooooooooooddddddddddddddd:....'',:oddddddddddo,....''',ldddddddddddddddddddolodddxO0OOOOOOO    //
//    kkkkkkkxooooooooooooooddddddddddddo,....'';oddddddddddl,.....'';odddddddddddddddddddddddddxOOOOOOOOO    //
//    kkkkkkkxoooooooooooooooooooooodddddl'....',:loddddddddc'.....'':oddddddddddddddddddddddddddkOOOOOOOO    //
//    kkkkkkkxooooooooooooooooooooooooddodl'....'',cldddddoc'......'cooooooooooooooooooooodddddddkOOOOOOOO    //
//    kkkkkkkxoooooollllcc:::ccllloooooddodo;......',;;;;;,......';lolccccccc::c::::;::clloddddddkOOOOOOOO    //
//    kkkkkkkxdlc:;,,'''.......''',;::::cloddl;................';:c:;;;:cldddddddddddddddddddddddkOOOOOOOO    //
//    kkkkkkkxo;'........................,lddddl:,,,''''',,,,:cc;,''''''';lddddddddddddddddddddddkOOOOOOOO    //
//    kkkkkkkkc'..................',;;;::ldddddddddoooooooddddl,.''''''''';ldddddddddddddddddddddkOOOOOOOO    //
//    kkkkkkkx:'.........'';::::ccloodddddddddddddddddddddddddl,.........'',cddddddddddddddddddddkOOOOOOOO    //
//    kkkkkkkx;......',;cloodddddooooooooddddddddddddddddddddddolcc::;;,'....,:ldddddddddddddddddkOOOOOOOO    //
//    kkkkkkkxl;,,;:coooooooooooooooooooooooddodddddddddddddddddddddddddocc:;;;cdddddddddddddddddxOOOOOOOO    //
//    kkkkkkkxdooooooooooooooooooooooooooooooooooddddddddddddddddddddddddddddddddddddddddddddddddxOOOOOOOO    //
//    kkkkkkkxoooooooooooooooooooooooooooooooodddddddddddddddddddddddddddddddddddddddddddddddddddxOOOOOOOO    //
//    kkkkkkkxoooooooooooooooooooooooooooooooooodddddddddddddddddddddddddddddddddddddddddddddddddxOOOOOOOk    //
//    kkkkkkkxoooooooooooooooooooooooooooooooooooodddddddddddddddddddddddddddddddddddddddddddddddxOOOOOOko    //
//    xkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOkOkdc:    //
//    xxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxl:::    //
//    xxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkdc;;::    //
//    xxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkko:;;;;:    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MW is ERC1155Creator {
    constructor() ERC1155Creator("Mark Wabbitz", "MW") {}
}
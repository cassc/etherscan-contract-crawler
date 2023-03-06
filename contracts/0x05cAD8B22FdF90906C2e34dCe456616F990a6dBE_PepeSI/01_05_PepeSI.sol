// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe by Seb Iacob
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    kkOOOOO00000Oxdollooddddddddddddddxd;'''''    //
//    kOOOOOO000Odlclllllooodddddddddxxxxdo:''''    //
//    OOOOOO000xllclloooooddddddddddxxxxxxxdc'..    //
//    OOOOO000dcllllooooddxxddddddddooodddxxd;..    //
//    OOOO00Oocclllllllodddddddxxdxdodoooodxd:..    //
//    OOO000o::::;;;::::cclooddxxdxddxddooodd;..    //
//    OO000x:,,,,,,,;;:::::::cloodxddxxxxdooo;..    //
//    OOO0Ol,',;;:::cc:;;;;;;;;::loodddxxxxdd:..    //
//    OOO00o;;;,';:c:,'',;::::::;;;:clddxxxxxc..    //
//    OO00K0kl:;',cc;,,;cc,,,;;:;;;,,;cloxxxxc..    //
//    OO000KKOl;';c::::;::;;;:::clc;,',,:lodxc..    //
//    OOOO00Kkc::odc:::::::cldxkkkxdoc;;:;;co;..    //
//    OOO000KOlclodollccodooodxkxxdolc:cllc;,'..    //
//    OOO0000Oo;;,,',cddoddddooolc:;;,,,;::;,;;;    //
//    OOOOO00Ol,'.''',:lc:loool:;,,'''',;::;;;;:    //
//    kOOOO000o'.;,''',;,',:::;,'..'''';:c;,;::c    //
//    kkOOO000Oc';,'',,:;'.'''.....',,;::;;:::;,    //
//    kkOOOO000kc','',;;'.......''',,;;;;::;,''.    //
//    kkkOOOO000Oo:'.''............'',,;;,'...''    //
//    kkkkOOO00klc:,..............''''''''......    //
//    kkkkkkO0x;...........'.....''......''.''.'    //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract PepeSI is ERC721Creator {
    constructor() ERC721Creator("Pepe by Seb Iacob", "PepeSI") {}
}
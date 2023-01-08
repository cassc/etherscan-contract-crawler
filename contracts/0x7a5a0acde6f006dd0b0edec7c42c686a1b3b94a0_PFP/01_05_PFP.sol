// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PepesForPeace
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0kdl:;,,','''',,;:ldk0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0kdolc:;;:::cccccccc:::;;::clodOKWMMMMMMMMMMMMMMMWNNXKKKKKXNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xoc:;:cclllllllllllllllllllllcccc:;:ld0NMMMMMWNKOxdollcc:::::ccllodxOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0dc:;:cllllllllllllllllllllllllllllllllcc:;cxKXOxoc:;::ccclllllllllccc:;;:lokKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc;:cllllllllllllllllllllllllllllllllllllllllc;;,,;:clllllllllllllllllllllllc:;:lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:;clllllllllllllllllllllllllllllllllllllllllllllc,';cllllllllllllllllllllllllllllc;:lONMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:;cllllllllllllllllllllllllllllllllllllllllllllllllc:',clllllllllllllllllllllllclllllc:;ckNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx:;cllllllllllllllllllllllllllllllllllllllllllllllllllll:';cllllllllllllllllllllllclllllllc:;l0WMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl;:llllllllllllllllllllllllllllllllllllllllllllllllllllllc,':lllllllllllllllllllllllllcllllllc;:kWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:;cllllllllllllllllllllllllllllllllcc:;;;;;;;;;;,,;;;;;;::c:';lllllllllllllllc::;;;,,,;;;;;,;;;;,,xWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWk;;cllllclllllllllllllllllllllllc:;;,;;;;;;:::::c::::::;;;;;;,.':cclllllllc:;,,,;,;;;:::ccccc::;;;,',dKWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWk;:llllllllllllllllllllllllllc:;,,,;::cllllllllllllllllllllllcc:;,,,;:cc:;,,;;;:clllllllllllllllllllc:;:lxKWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMO:;lllllllllllllllllllllllllc;,,;:cllllllllllllllllllllllllllllllllc:;,'',;:cllllllllllllllllllllllllllllc;:o0WMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMKc;cllllllllllllllllllllllll:;,:cllllllllllllllllllllllllllllllllllllllc;',cllllllllllllllllllllllllllccccccc;;oKWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNo,clllllllllllllllllllllllllccllllllllllllllllllllccc::;;;;;;;;,;;;;;;::c:,':llllllllllllccc::;;;,,,,;;;;;;;,,,.,d0XWMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWk;;llllllllllllllllllllllclllllllllllllllllllc:;;,,,;;;;;;;;:::::::;;;;;;;,'.,cllllcc::;;,,;;;;;;;:::::::;;;;;;;;;;:coOWMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMKd,,clllllllllllllllllllllllllllllcllllllllc:;,,,;;::cccc::;;;;,,,,,,;;;;;:::;,',;:;,,,;;;::::::;;,,;;;;;;;;;;;;;,;;,,,';0MMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMXx:'.;lllllllllllllllllllllllllllllllllllc:;,,,;:ccc:;;;,,,,;;;;:::::::::;;;;;,,;:,.';::::;;,,;;,;;;::ccccllllllllllccc:;,,lONMMM    //
//    MMMMMMMMMMMMMMMMMMMNkc;:,':lllllllllllllllllllllllllllllllc:;,,,;:ccc:;,,,;;;:ccllllllllllllllllllcc:;,,..,,,;;;;:cccllllllllllllllllllclllllllc:;cdOX    //
//    MMMMMMMMMMMMMMMMMWOl;:lc',clllllllllllllllllllllllllcc::;,,,;:cc:;;,,,;:ccllllllllllllllllllllllllllllc:'.';cllllllccc::;;,,'''........,:cc:::;;;:;;,;    //
//    MMMMMMMMMMMMMMMMXo;:cll:';lllllllllllllllllc:::;;;,,,,,;;:::;;,,,;;:clllcllllllllllllccc:::;;;;;::::;;;:c;';cc:;;:clloo:.    .''.       'o0KK0Okxdl;cd    //
//    MMMMMMMMMMMMMMNk:;cllll:';lllllllllllllllll:;;;;;;;;::;;,,;;;;:cclllllllllllcc::;,''....  .,lxOO0000Okxo;,,,codkOKXNXx;.    .xNNx.        ,kWMMMMWkoKM    //
//    MMMMMMMMMMMMMKo;:llllll;':llllllllllllllc:;;;;,,,,;;;;;;:ccllllllllllcc:;;,'...  ...        .,oKWMMMMMMKlo0XWMMMMMWO;       .ckkc.         .kWMMW0oOWM    //
//    MMMMMMMMMMMWO:;clllllllc:cllllllllllllllc:;,',:::ccclllllllllllllc:;;cloc'      :0XO,          .oXMMMMNddNMMMMMMMWd.  .l00l.    .;l:.       ;KMNx:xWMM    //
//    MMMMMMMMMMNd;:cllllllllllllllllllllllllllllc;,,:cclllllllllllc:;;cox0XKo.       ;k0x'            :KMMNo'lkKNWMMMWx.   .dXXd.    :XMNl       .dxc;'oNMM    //
//    MMMMMMMMMKl;:cllllllllllllllllllllllllllllllcc:,,,,;;;;;;;;:clox0NWMM0;     .     .    .          lNKl,..;:cloxkx'      ..      .:oc.       .,;::;xWMM    //
//    MMMMMMMW0c;clllllllllllllllllllllllllllllllllcllcc:;;;;;,',cd0NWMMMM0,   .dO0O:      :O0d.        .l:;:',clcc:;;;'...                  ...,;:c:;ckNMMM    //
//    MMMMMMWO:;cllllllllllllllllllllllllllllllllllllllllllllllcc:;:codk00c    'kXXKc      lKXk'        .,:c,.';;:cc:;;,,,,,,''''''''''',,,;;;:;;,,cx0NMMMMM    //
//    MMMMMWO:;clllllllllllllllllllllllllllllllllllllllllllllllc:,;;:::;:;'.    ....        ...      .';cc;,,;:;;;,,,;:::;;;;;,;;;;;;;;;;;;;;;;;;':KMMMMMMMM    //
//    MMMMWO:;clllllllllllllllllllllllllllllllllllllllllllllllllc:;;,,,;;::::;,,''......     .....',:::;,,,:clllllcc:;,,;:clllllcccccccccccclllc:;kWMMMMMMMM    //
//    MMMWO:;clllllllllllllllllllllllllllllllllllllllllllllllllllllllc::;;,,,,;;;;;;:;;;;;;;;;;;;;;,,,,;:cllllllllllllc:;,,;clllllllllllllllcc:;lOWMMMMMMMMM    //
//    MMMKc;cllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllcc::;;;;;;;;;;;;;,,...,;:cccllllllllllllllllllc:,,,:clllllcc::;;;:lx0NMMMMMMMMMMM    //
//    MMXl,clllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllc:;,,,;cllllllllllllllllllllllllllcc;',,,,,,;;,,;,,:xXWMMMMMMMMMMMM    //
//    MWd;:lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllcc::::::;;;,,,,;:cllllllllllllllllllllllllllllllll:,.,:ccccllllc:;:dKWMMMMMMMMMM    //
//    M0:;lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllc:;;;;;;;;;;:cclllllllllllllllllllllllllllllllllllllc;';cllllllllllc;;oKWWWMMMMMM    //
//    No,cllllllllllllllllllllllllllcc::clllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllc::cllllllllllcc,';lood0WMMM    //
//    O;;lllllllllllllllllllllllllc;,,;;cllclllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllclc:;,;;:llol::0MMM    //
//    o,clllllllllllllllllllllllc;,,:cllllcc::;;;;:::ccclllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllc:;,,;:coooooool;xMMM    //
//    :;clllllllllllllllllllllll;';clllc:;,;;;::::;;;;;;;,;;::ccclllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllcc:;,;;;cloooooooooo::OMMM    //
//    ,:lllllllllllllllllllllllc,,clllc;,;loooooooooooollc::;;;;;;;;;::ccccllllllllllllllllllllllllllllllllllllllllllllllccc::;;;;;;;:cloooooooooooooc:xWMMM    //
//    ,:lllllllllllllllllllllllc',cllc;'cooooooooooooooooooooooolcc::;;;;;;;;;;;;;;;;;:::::::cccccccccccccccccc::::;;;;;;;;;;;::clloooooooooooooool::l0WMMMM    //
//    'clllllllllllllllllllllllc;;cll:';oooooooooooooooooooooooooooooooooollccc::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::ccloooooooooooooooooooolc:cox0NMMMMMM    //
//    'cllllllllllllllllllllllllcclll:';ooooooooolc:::ccloooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooolc:;coxOXWMMMMMMMMM    //
//    ,:lllllllllllllllllllllllllllllc,,coooooooo:,coollcc::::ccloooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooollcc:;;;;;;,cOWMMMMMMMMMMMM    //
//    ,:llllllllllllllllllllllllllllllc,,coooooool::oO000Okxdollccc:::::cccllloooooooooooooooooooooooooooooooooooooolllccc:::;;:::;'.,:clooooc:oKWMMMMMMMMMM    //
//    c;cllllllllllllllllllllllllllllllc;,:ooooooooc::lxO00000000OOkxddollllccccccc:::::::::::::::::::::::::::::,,;:::::::::cclooddl:;;:loooool::kNMMMMMMMMM    //
//    d,clllllllllllllllllllllllllllllllc:,,cooooooool::clxO000000000000000000OOOkkkxxxxdddddddooooodddddddxxxkxoc;:lddddddddddddddddol;,:ooooooc;dNMMMMMMMM    //
//    Kc;cllllllllllllllllllllllllllllllllc;,,:looooooool:::coxO0000000OOOOkOOOO0000000000000000000000000000000000kc;cdddddddddddddddddoc,;loooool;dNMMMMMMM    //
//    Wk;:llllllllllllllllllllllllllllllllllc:,,;cooooooooolc::cllccllccccccccccclllooxk000000000000000000000000000Ol;ldddddddddddddddddd:,cooooooc:OMMMMMMM    //
//    MNd;:lllllllllllllllllllllllllllllllllllc:;,;:loooooooooolc;,',;:lodddddddooolcc:ccloxO00000000000000000000000x;cddddddddddddddddol,;looooool;xMMMMMMM    //
//    MMNd;:lllllllllllllllllllllllllllllllllllllc:;,;:cooooooooooolc::;;::ccoodddddddddolc:cloxO000000000000000000Ol;ldddddddddddddoc:;;:loooooooc:OMMMMMMM    //
//    MMMNd;:cllllllllllllllllllllllllllllllllllllllc:;,;;:loooooooooooool::;;:::::cloodddddolc:cloxO000000000000kdc:ldddddddollc:::;;:coooooooooc;xNMMMMMMM    //
//    MMMMWO:;cllllllllllllllllllllllllllllllllllllllllcc;,,;;:loooooooooooooollc:::;;::::::cclllc::cclloodddollc:;:llcc::::::;:::cloooooooooooc:cOWMMMMMMMM    //
//    MMMMMMKo;:cllllllllllllllllllllllllllllllllllllllllllc:;;;;;:cloooooooooooooooooollc::::::::::;;,''....'',,;::;;::::ccloooooooooooooolc:cokNMMMMMMMMMM    //
//    MMMMMMMW0l;:cllllllllllllllllllllllllllllllllllllllllllllcc:;,;;;::clooooooooooooooooooooooooooollllllllloooooooooooooooooooooooolc:codkXWMMMMMMMMMMMM    //
//    MMMMMMMMMNOo:;ccllllllllllllllllllllllllllllllllllllllllllllllcc:;;;;;;;::clllooooooooooooooooooooooooooooooooooooooooooolcc:;;,',lkKWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWKdc;:cllllllllllllllllllllllllllllllllllllllllllllllllllcc:;;;;;;;;;;;:::cccclllllllllllllllllccccc::::;;;;;;;;;,'':dKWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNOdc:;:clclllllllllllllllllllllllllllllllllllllllllllllllllllllcc:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::cccc:;cdONMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMN0xoc:;:cllllllllllllllllllllllllllllllllllllllllllllllllllllclllllllllllllllllcccllllllllllllllllllc:;:cdONMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWN0xdlc:;::ccllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllc:;:cox0NMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWX0kxolc::;;::ccllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllcc:;:cldx0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0Oxddolc:::;;:::ccccllllllllllllllllllllllllllllllllllllllllllllccc::;;:clodk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNX0Okkxddollcc:::::;;;:::::::ccccccccccccc::::::;;;;;;:ccloodxkOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0Okxdollc::;;;,,,,,,,,,,,,,,,;;;;;:clodkO0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PFP is ERC721Creator {
    constructor() ERC721Creator("PepesForPeace", "PFP") {}
}
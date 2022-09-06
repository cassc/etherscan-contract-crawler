// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GoodHeat Customer NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    MMMMMMMMMMMWXOxlc;,,,,,;:ox0XWMMMMMMMMMM    //
//    MMMMMMMMWXOdc:;,,,,;;,,,,,;:lx0NMMMMMMMM    //
//    MMMMMMWKxc;,,,,,,;;;;;,,,,,;;;:lxXWMMMMM    //
//    MMMMMNkc,,,,,,,;cloooolc;;;;;;;,,cONMMMM    //
//    MMMWXd;,,,;;;lx0XNWWWWNXKOdc;,,,,,:xXMMM    //
//    MMMXd;,,,;;ckXWMMMMMMMMMMMW0o;,,,,,;dNMM    //
//    MMWk:,,;;;c0WMMMMMMMMMMMMMMMXd;,,,,,:OWM    //
//    MMNd,,;;;;xNMMMMMMMMMMMMMMMMM0c,;;;;;xNM    //
//    MMXo;;;;,:kWMMMMMMMMMMMMMMMMMKl;;;;;;dNM    //
//    MMNx;;,,,,oXMMMMMMMMMMMMMMMMWO:;;;;;;xWM    //
//    MMW0c,,,,,;dXMMMMMMMMMMMMMMW0l;;;;;;l0MM    //
//    MMMNx;,,,,,;lkXWMMMMMMMMMN0d:;;;;;;:kWMM    //
//    MMMMNk:,,,;;;;cdxO0KXX0kdl:;;;;;;;cONMMM    //
//    MMMMWNOo:;;;;;;;;;;ldkl,,,;;;;;;:o0WMMMM    //
//    MMMNOloxxoc;;;;;;;,:lxd;,,;;;:clollkNMMM    //
//    MMWOc;;;coooolc:;;,;cdd:;:clllc:;;;:kWMM    //
//    MMNd;;;;;;;:loooooc;;dOollll:;;;;;;,oXMM    //
//    MMXo,,,;dd:;;;;;cdl,;okc,,,,,;dx:;,,lKMM    //
//    MMNd;,,;dx:;;;;;cdl;;okl,,,,,;dd;,,;oKMM    //
//    MMNx;,,;dd;;;;;,cxl;,lko;;,,,;dd;,,;oXMM    //
//    MMWk;,;:xd;;;;;;lxc,,cOd;;,;;;ox:,,;dNMM    //
//    MMNd;,;cxo;;;;;;ox:;;ckx;,;;;,cxc,,;dXMM    //
//    0kkxddodkl;;;;;;dx:;;ckx;;;;,,cxdloddxk0    //
//    :,;:cookkc;;;;,;xx:;;:kk:,,,,,:xxolc:;;c    //
//    xollcccdxc;;,,,:kx:;;:xk:,,,,,;dd::cloox    //
//    dlxxldkKk:,,,,,ckd;;;;dOc,;;;,,d0xolxkld    //
//    o:lollx0Odooolox0d;;,,o0xloooolk0xllol:o    //
//    NK000kxo::cllodddc;;,,:oooolcc:coxO000KN    //
//    MMMMMNK0xoooooooolllllllloooodddOKWMMMMM    //
//    MMMMMMMXdcclooooooxKNKdoooooolccxXMMMMMM    //
//    MMMMMMNkc;;;;;;;;;oKW0l;,,,;;;;;ckNMMMMM    //
//    MMMMMMWN0dcccccccd0WWW0ocllccccdKWWMMMMM    //
//    MMMMMMMMXxlcccccloONMWKdlcccccld0WMMMMMM    //
//    MMMMMMMNx;;;;;,,,;c0WXd;;;;;;;,,lKMMMMMM    //
//    MMMMMMMNOoc:;,,;:cdKWNkoc;;;;;;cdXMMMMMM    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract GHT is ERC721Creator {
    constructor() ERC721Creator("GoodHeat Customer NFT", "GHT") {}
}
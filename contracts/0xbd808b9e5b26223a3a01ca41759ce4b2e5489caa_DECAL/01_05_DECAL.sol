// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Decal
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    A symbol of permissionless creativity                 //
//                                                          //
//    MMMMMMMMMMMMMMXO0WMMMMMMMMMMMWKkKWMMMMMMMMMMW0OXMM    //
//    MMMMMMMMMMMMXx, .lXMMMMMMMMWKo. .dNMMMMMMMWOc. ,OW    //
//    MMMMMMMMMMXx,   'dXMMMMMWWKo.   ;kNMMMMMWOc.  .c0W    //
//    MMMMMMMMXx,   'dXWMMMMWKo;.   ;kNMMMMMWOc.  .c0WMM    //
//    MMMMMMXx,   'oXWMMMMWKo.    ,kNMMMMMWOc.  .:OWMMMM    //
//    MMMMXx,   'dXMMMMMWKo.   .,kNMMMMMWOc.  .cOWMMMMMM    //
//    MMXx,   'oXMMMMMWKo.   ,kKNMMMMMW0c.  .cOWMMMMMMMM    //
//    WO,   'dXWMMMMWKo.   ;kNMMMMMMWOc.  .c0WMMMMMWNWMM    //
//    W0c.'dXMMMMMWKo.   ,kNMMMMMMWOc.  .cOWMMMMMNk;'oKM    //
//    MMWKXMMMMMWKo.   ,kNMMMMMMWOc.  .c0WMMMMMNk;   'kW    //
//    MMMMMMMMWKo.   ,kNMMMMMW0dc.  .cOWMMMMMNk,   .oKWM    //
//    MMMMMMWKo.   ;kNMMMMMWOc.   .c0WMMMMMNk;   .oKWMMM    //
//    MMMMWKo.   ,kNMMMMMWOc.   .cOWMMMMMNk;   .oKWMMMMM    //
//    MMWKo.   ,kNMMMMMWOc.  .cd0WMMMMMNk;   .oKWMMMMMMM    //
//    WKo.   ,kNMMMMMW0c.  .cOWMMMMMMNk;   .oKWMMMMMMMMM    //
//    Wk'  ,kNMMMMMWOc.  .c0WMMMMMMNk;   .oKWMMMMWXdoOWM    //
//    MWKxkNMMMMMWOc.  .cOWMMMMMMNk;   .oKWMMMMWXo'  .kW    //
//    MMMMMMMMMWOc.  .c0WMMMMMNKk;   .lKWMMMMMXo'   ,xXM    //
//    MMMMMMMW0c.  .cOWMMMMMNk;.   .oKWMMMMMXo'   ,xXMMM    //
//    MMMMMWOc.  .c0WMMMMMNk;    .oKWMMMMWXd.   ,xXMMMMM    //
//    MMMWOc.  .:OWMMMMMNk;   .;oKWMMMMWXd'   ,xXMMMMMMM    //
//    MW0c.  .cOWMMMMMNk;   .oKWWMMMMWXo'   ,xXMMMMMMMMM    //
//    Wk.  .:OWMMMMMMNo.  .oKWMMMMMMMK:   ,xXMMMMMMMMMMM    //
//    MXd;cOWMMMMMMMMWKo;oKWMMMMMMMMMWOc:xXMMMMMMMMMMMMM    //
//    MMMNWMMMMMMMMMMMMWWWMMMMMMMMMMMMMWWMMMMMMMMMMMMMMM    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract DECAL is ERC721Creator {
    constructor() ERC721Creator("Decal", "DECAL") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BFL Old Mailbox
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWW''\wwww/''WWWWWWWWWW    //
//    WWWWWWWWWW'''\ww/'''WWWWWWWWWW    //
//    WWWWWWWWWW''''''''''WWWWWWWWWW    //
//    MMMMMMMMMM\''''''''/MMMMMMMMMM    //
//    MMMMMMMMMMM\''''''/MMMMMMMMMMM    //
//    MMMMMMMMMM''M\''/M''MMMMMMMMMM    //
//    MMMMMMMMMMMm''WW''mMMMMMMMMMMM    //
//    MMMMMMMMMMMMMm''mMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                      //
//                                      //
//////////////////////////////////////////


contract PSA is ERC1155Creator {
    constructor() ERC1155Creator("BFL Old Mailbox", "PSA") {}
}
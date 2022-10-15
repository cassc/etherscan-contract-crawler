// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPELOCKED4EVER
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//                                                                                          //
//    PPPP  EEEE PPPP  EEEE L     OOO   CCC K  K EEEE DDD  4  4 EEEE V     V EEEE RRRR      //
//    P   P E    P   P E    L    O   O C    K K  E    D  D 4  4 E    V     V E    R   R     //
//    PPPP  EEE  PPPP  EEE  L    O   O C    KK   EEE  D  D 4444 EEE   V   V  EEE  RRRR      //
//    P     E    P     E    L    O   O C    K K  E    D  D    4 E      V V   E    R R       //
//    P     EEEE P     EEEE LLLL  OOO   CCC K  K EEEE DDD     4 EEEE    V    EEEE R  RR     //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract LOCKED4EVER is ERC721Creator {
    constructor() ERC721Creator("PEPELOCKED4EVER", "LOCKED4EVER") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pinball Destiny
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    o--o  o-O-o o   o o--o    O  o    o        //
//    |   |   |   |\  | |   |  / \ |    |        //
//    O--o    |   | \ | O--o  o---o|    |        //
//    |       |   |  \| |   | |   ||    |        //
//    o     o-O-o o   o o--o  o   oO---oO---o    //
//                                               //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract ball is ERC721Creator {
    constructor() ERC721Creator("Pinball Destiny", "ball") {}
}
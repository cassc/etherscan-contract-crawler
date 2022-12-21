// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SEEDS: BLOOM by phraze
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//     o-o  o--o o--o o-o    o-o       //
//    |     |    |    |  \  |          //
//     o-o  O-o  O-o  |   O  o-o       //
//        | |    |    |  /      |      //
//    o--o  o--o o--o o-o   o--o       //
//                                     //
//                                     //
//    o--o  o     o-o   o-o  o   o     //
//    |   | |    o   o o   o |\ /|     //
//    O--o  |    |   | |   | | O |     //
//    |   | |    o   o o   o |   |     //
//    o--o  O---o o-o   o-o  o   o     //
//                                     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract BLOOM is ERC721Creator {
    constructor() ERC721Creator("SEEDS: BLOOM by phraze", "BLOOM") {}
}
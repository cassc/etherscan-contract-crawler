// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Neighborhood
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//    o   o            o    o            o               o     //
//    |\  |     o      |    |            |               |     //
//    | \ | o-o   o--o O--o O-o  o-o o-o O--o o-o o-o  o-O     //
//    |  \| |-' | |  | |  | |  | | | |   |  | | | | | |  |     //
//    o   o o-o | o--O o  o o-o  o-o o   o  o o-o o-o  o-o     //
//                   |                                         //
//                o--o                                         //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract ALEMAC is ERC721Creator {
    constructor() ERC721Creator("Neighborhood", "ALEMAC") {}
}
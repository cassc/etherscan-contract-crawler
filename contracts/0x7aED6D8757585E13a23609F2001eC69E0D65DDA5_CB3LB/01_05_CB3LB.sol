// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Creations by 3LandBoy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Creations by 3LandBoy    //
//                             //
//                             //
/////////////////////////////////


contract CB3LB is ERC721Creator {
    constructor() ERC721Creator("Creations by 3LandBoy", "CB3LB") {}
}
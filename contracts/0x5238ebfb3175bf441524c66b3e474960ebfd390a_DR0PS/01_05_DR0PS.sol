// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AirDrops by Re1st
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    AirDrops by "Re1st"    //
//                           //
//                           //
///////////////////////////////


contract DR0PS is ERC721Creator {
    constructor() ERC721Creator("AirDrops by Re1st", "DR0PS") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ordinals Ape OBAYC
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Bitcoin Ordinsld Bayc    //
//                             //
//                             //
/////////////////////////////////


contract OBAYCord is ERC721Creator {
    constructor() ERC721Creator("Ordinals Ape OBAYC", "OBAYCord") {}
}
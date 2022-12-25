// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM Factory
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    GGGGGGGGGGGGG        MMMMMMMMMMMMMMMMM     //
//    GGGGGGGGGGGGG        MMMMMMMMMMMMMMMMM     //
//    GGG       GGG        MMMM   MMM   MMMM     //
//    GGG       GGG        MMMM   MMM   MMMM     //
//    GGG                  MMMM   MMM   MMMM     //
//    GGG     GGGGG        MMMM   MMM   MMMM     //
//    GGG     GGGGG        MMMM   MMM   MMMM     //
//    GGG       GGG        MMMM   MMM   MMMM     //
//    GGG       GGG        MMMM   MMM   MMMM     //
//    GGGGGGGGGGGGG        MMMM   MMM   MMMM     //
//    GGGGGGGGGGGGG        MMMM   MMM   MMMM     //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract GM is ERC721Creator {
    constructor() ERC721Creator("GM Factory", "GM") {}
}
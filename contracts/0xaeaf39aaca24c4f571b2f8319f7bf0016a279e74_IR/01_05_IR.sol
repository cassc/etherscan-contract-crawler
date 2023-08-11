// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Imagined Realms: Concept Art Series
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    Imagined Realms: Concept Art Series    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract IR is ERC721Creator {
    constructor() ERC721Creator("Imagined Realms: Concept Art Series", "IR") {}
}
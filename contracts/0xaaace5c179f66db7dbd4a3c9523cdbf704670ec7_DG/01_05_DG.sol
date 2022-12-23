// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Doomergirl
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    Limited edition. Only 10 available.    //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract DG is ERC721Creator {
    constructor() ERC721Creator("Doomergirl", "DG") {}
}
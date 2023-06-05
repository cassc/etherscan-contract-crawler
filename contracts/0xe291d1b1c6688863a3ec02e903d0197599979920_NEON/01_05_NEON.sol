// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Neon Americana
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    Neon Americana, by Nathan A. Bauman    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract NEON is ERC721Creator {
    constructor() ERC721Creator("Neon Americana", "NEON") {}
}
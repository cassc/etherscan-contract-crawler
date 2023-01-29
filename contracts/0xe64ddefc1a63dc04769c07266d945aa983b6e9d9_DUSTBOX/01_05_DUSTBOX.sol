// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dust Box
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    Dust Box by Nathan A. Bauman    //
//                                    //
//                                    //
////////////////////////////////////////


contract DUSTBOX is ERC721Creator {
    constructor() ERC721Creator("Dust Box", "DUSTBOX") {}
}
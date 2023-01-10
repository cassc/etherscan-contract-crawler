// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flowers O2
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    ❀ ❀ ❀ ❀ ❀    //
//                 //
//                 //
/////////////////////


contract O2 is ERC721Creator {
    constructor() ERC721Creator("Flowers O2", "O2") {}
}
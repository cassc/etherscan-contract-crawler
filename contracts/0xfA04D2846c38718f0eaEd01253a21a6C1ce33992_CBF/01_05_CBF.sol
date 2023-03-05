// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CosmicBlaze
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Cosmic Blaze Farmer    //
//                           //
//                           //
///////////////////////////////


contract CBF is ERC721Creator {
    constructor() ERC721Creator("CosmicBlaze", "CBF") {}
}
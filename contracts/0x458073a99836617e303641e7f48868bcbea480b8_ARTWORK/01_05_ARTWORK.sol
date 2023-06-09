// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Artworks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Artworks by Vrenarn    //
//                           //
//                           //
///////////////////////////////


contract ARTWORK is ERC721Creator {
    constructor() ERC721Creator("Artworks", "ARTWORK") {}
}
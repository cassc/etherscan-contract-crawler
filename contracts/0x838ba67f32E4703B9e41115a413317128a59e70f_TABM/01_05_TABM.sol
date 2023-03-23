// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: This Artwork Won't be in a Museum
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    For the culture    //
//                       //
//                       //
///////////////////////////


contract TABM is ERC721Creator {
    constructor() ERC721Creator("This Artwork Won't be in a Museum", "TABM") {}
}
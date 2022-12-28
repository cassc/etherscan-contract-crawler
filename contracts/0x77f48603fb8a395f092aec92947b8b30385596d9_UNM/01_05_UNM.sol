// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Untitled Materials
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Untitled Materials    //
//                          //
//                          //
//////////////////////////////


contract UNM is ERC721Creator {
    constructor() ERC721Creator("Untitled Materials", "UNM") {}
}
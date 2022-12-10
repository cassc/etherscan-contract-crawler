// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MinimalistMuseum
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Minimalist Museum    //
//                         //
//                         //
/////////////////////////////


contract AMM is ERC721Creator {
    constructor() ERC721Creator("MinimalistMuseum", "AMM") {}
}
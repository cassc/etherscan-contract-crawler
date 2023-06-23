// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jordan Hile Photography
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    All rights reserved        //
//    Jordan Hile Photography    //
//                               //
//                               //
///////////////////////////////////


contract JHP is ERC721Creator {
    constructor() ERC721Creator("Jordan Hile Photography", "JHP") {}
}
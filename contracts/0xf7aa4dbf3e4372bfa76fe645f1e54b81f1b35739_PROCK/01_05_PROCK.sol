// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PixelRock
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    IT'S A PIXEL ROCK    //
//                         //
//                         //
/////////////////////////////


contract PROCK is ERC721Creator {
    constructor() ERC721Creator("PixelRock", "PROCK") {}
}
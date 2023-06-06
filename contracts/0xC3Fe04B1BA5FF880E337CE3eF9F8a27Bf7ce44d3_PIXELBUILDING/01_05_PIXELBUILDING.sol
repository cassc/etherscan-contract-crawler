// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PIXEL BUILDING
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    PIXEL BUILDING    //
//                      //
//                      //
//////////////////////////


contract PIXELBUILDING is ERC721Creator {
    constructor() ERC721Creator("PIXEL BUILDING", "PIXELBUILDING") {}
}
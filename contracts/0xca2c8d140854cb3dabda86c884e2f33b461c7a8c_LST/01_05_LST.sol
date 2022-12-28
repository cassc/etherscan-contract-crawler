// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LSTPXL
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    LostPixels    //
//                  //
//                  //
//////////////////////


contract LST is ERC721Creator {
    constructor() ERC721Creator("LSTPXL", "LST") {}
}
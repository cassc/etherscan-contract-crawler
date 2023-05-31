// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ray's Calligraphy Collage Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    |||RCCA|||    //
//                  //
//                  //
//////////////////////


contract RCCA is ERC721Creator {
    constructor() ERC721Creator("Ray's Calligraphy Collage Art", "RCCA") {}
}
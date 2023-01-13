// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GLYPH
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//     __     _         //
//    /__|\_/|_)|_|     //
//    \_||_| |  | |     //
//                      //
//                      //
//////////////////////////


contract GLY is ERC721Creator {
    constructor() ERC721Creator("GLYPH", "GLY") {}
}
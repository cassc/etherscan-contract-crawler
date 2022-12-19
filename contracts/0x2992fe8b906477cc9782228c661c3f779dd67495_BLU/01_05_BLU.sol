// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: blue spectre
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    blue spectre 20/20    //
//                          //
//                          //
//////////////////////////////


contract BLU is ERC721Creator {
    constructor() ERC721Creator("blue spectre", "BLU") {}
}
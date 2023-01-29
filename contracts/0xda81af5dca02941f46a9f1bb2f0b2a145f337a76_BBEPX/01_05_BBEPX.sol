// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: bbepX
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    XOXO - bbep    //
//                   //
//                   //
///////////////////////


contract BBEPX is ERC721Creator {
    constructor() ERC721Creator("bbepX", "BBEPX") {}
}
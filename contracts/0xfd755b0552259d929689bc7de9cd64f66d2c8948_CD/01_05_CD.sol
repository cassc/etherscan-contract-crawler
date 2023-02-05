// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Collaborative Dreamers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    0000 0000    //
//    0000 0001    //
//    0000 1001    //
//                 //
//                 //
//                 //
/////////////////////


contract CD is ERC721Creator {
    constructor() ERC721Creator("Collaborative Dreamers", "CD") {}
}
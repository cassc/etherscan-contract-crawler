// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dive
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//                   //
//    |) | \/ [-     //
//                   //
//                   //
//                   //
//                   //
///////////////////////


contract DIVE is ERC721Creator {
    constructor() ERC721Creator("Dive", "DIVE") {}
}
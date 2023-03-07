// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alex's Atama #119
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Alex's Atama #119    //
//                         //
//                         //
/////////////////////////////


contract AATAMA is ERC721Creator {
    constructor() ERC721Creator("Alex's Atama #119", "AATAMA") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Scream-310
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    AAAAAHHHH    //
//                 //
//                 //
/////////////////////


contract SCREAM is ERC721Creator {
    constructor() ERC721Creator("Scream-310", "SCREAM") {}
}
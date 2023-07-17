// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: reflections
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    o.o.o.o.o    //
//                 //
//                 //
/////////////////////


contract R5 is ERC721Creator {
    constructor() ERC721Creator("reflections", "R5") {}
}
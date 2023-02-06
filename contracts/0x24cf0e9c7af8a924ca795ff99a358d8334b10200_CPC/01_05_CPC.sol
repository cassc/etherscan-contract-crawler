// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - Pepe Cube
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    This Pepe Cube may or may not be notable.    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract CPC is ERC721Creator {
    constructor() ERC721Creator("Checks - Pepe Cube", "CPC") {}
}
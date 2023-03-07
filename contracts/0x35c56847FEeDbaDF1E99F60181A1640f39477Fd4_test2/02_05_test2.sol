// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Testing
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    hey this is a test    //
//                          //
//                          //
//////////////////////////////


contract test2 is ERC721Creator {
    constructor() ERC721Creator("Testing", "test2") {}
}
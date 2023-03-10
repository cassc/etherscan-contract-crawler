// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Contract 1
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    test 1    //
//              //
//              //
//////////////////


contract tteesstt is ERC1155Creator {
    constructor() ERC1155Creator("Test Contract 1", "tteesstt") {}
}
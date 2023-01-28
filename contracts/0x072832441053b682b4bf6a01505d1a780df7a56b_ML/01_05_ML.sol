// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Memory Lane
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    A glimpse of purple.     //
//                             //
//                             //
/////////////////////////////////


contract ML is ERC1155Creator {
    constructor() ERC1155Creator("Memory Lane", "ML") {}
}
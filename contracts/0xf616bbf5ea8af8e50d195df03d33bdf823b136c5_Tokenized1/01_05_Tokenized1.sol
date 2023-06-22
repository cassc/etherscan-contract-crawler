// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tokenized Chapter 1
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Tokenized Chapter 1    //
//                           //
//                           //
///////////////////////////////


contract Tokenized1 is ERC1155Creator {
    constructor() ERC1155Creator("Tokenized Chapter 1", "Tokenized1") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bull Shot
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    Good Job    //
//                //
//                //
////////////////////


contract BST is ERC721Creator {
    constructor() ERC721Creator("Bull Shot", "BST") {}
}
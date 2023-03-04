// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AI Agent v4
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//          _       _____      //
//         / \     |_   _|     //
//        / _ \      | |       //
//       / ___ \     | |       //
//     _/ /   \ \_  _| |_      //
//    |____| |____||_____|     //
//                             //
//                             //
//                             //
/////////////////////////////////


contract AI is ERC721Creator {
    constructor() ERC721Creator("AI Agent v4", "AI") {}
}
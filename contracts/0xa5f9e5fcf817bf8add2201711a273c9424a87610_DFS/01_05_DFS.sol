// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dancinfreakshow
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    DFSImages    //
//                 //
//                 //
/////////////////////


contract DFS is ERC721Creator {
    constructor() ERC721Creator("Dancinfreakshow", "DFS") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Project Alpha
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    PROJECT ALPHA     //
//                      //
//                      //
//////////////////////////


contract Alpha is ERC721Creator {
    constructor() ERC721Creator("Project Alpha", "Alpha") {}
}
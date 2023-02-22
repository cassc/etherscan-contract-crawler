// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AI Art Maze
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    AI Art Maze    //
//                   //
//                   //
///////////////////////


contract AAM is ERC721Creator {
    constructor() ERC721Creator("AI Art Maze", "AAM") {}
}
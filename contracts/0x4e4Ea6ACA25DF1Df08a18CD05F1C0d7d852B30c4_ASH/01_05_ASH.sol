// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ash Blocks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Ash Blocks    //
//                  //
//                  //
//////////////////////


contract ASH is ERC721Creator {
    constructor() ERC721Creator("Ash Blocks", "ASH") {}
}
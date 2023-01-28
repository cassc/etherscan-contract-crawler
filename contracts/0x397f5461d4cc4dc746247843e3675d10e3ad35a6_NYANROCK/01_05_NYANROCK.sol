// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nyan Rocks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    NYAN ROCKS    //
//                  //
//                  //
//////////////////////


contract NYANROCK is ERC721Creator {
    constructor() ERC721Creator("Nyan Rocks", "NYANROCK") {}
}
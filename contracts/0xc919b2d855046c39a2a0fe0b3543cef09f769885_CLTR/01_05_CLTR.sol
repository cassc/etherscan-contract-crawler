// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COLLECTOOR
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    COLLECTOOR    //
//                  //
//                  //
//////////////////////


contract CLTR is ERC721Creator {
    constructor() ERC721Creator("COLLECTOOR", "CLTR") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Deep Space
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Deep Space    //
//                  //
//                  //
//////////////////////


contract DeepSpace is ERC721Creator {
    constructor() ERC721Creator("Deep Space", "DeepSpace") {}
}
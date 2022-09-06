// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DARKWORLD
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Dark world    //
//                  //
//                  //
//////////////////////


contract DARK is ERC721Creator {
    constructor() ERC721Creator("DARKWORLD", "DARK") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: testofproof
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    top    //
//           //
//           //
///////////////


contract top is ERC721Creator {
    constructor() ERC721Creator("testofproof", "top") {}
}
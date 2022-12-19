// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LUF Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    LUF    //
//           //
//           //
///////////////


contract LUF is ERC721Creator {
    constructor() ERC721Creator("LUF Collection", "LUF") {}
}
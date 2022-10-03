// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    sss    //
//           //
//           //
///////////////


contract TCdd is ERC721Creator {
    constructor() ERC721Creator("Test Collection", "TCdd") {}
}
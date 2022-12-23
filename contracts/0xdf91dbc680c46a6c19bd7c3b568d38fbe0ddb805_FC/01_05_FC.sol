// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fun Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    F&C    //
//           //
//           //
///////////////


contract FC is ERC721Creator {
    constructor() ERC721Creator("Fun Collection", "FC") {}
}
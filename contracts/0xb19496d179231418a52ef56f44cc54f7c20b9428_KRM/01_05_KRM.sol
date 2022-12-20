// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Karima
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    KRM    //
//           //
//           //
///////////////


contract KRM is ERC721Creator {
    constructor() ERC721Creator("Karima", "KRM") {}
}
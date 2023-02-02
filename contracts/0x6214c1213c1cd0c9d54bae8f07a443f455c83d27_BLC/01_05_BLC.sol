// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blind choice
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    BLC    //
//           //
//           //
///////////////


contract BLC is ERC721Creator {
    constructor() ERC721Creator("Blind choice", "BLC") {}
}
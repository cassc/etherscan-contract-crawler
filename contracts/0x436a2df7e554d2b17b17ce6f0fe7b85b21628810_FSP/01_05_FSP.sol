// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test  Framed Schematic Print
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    FSP    //
//           //
//           //
///////////////


contract FSP is ERC721Creator {
    constructor() ERC721Creator("Test  Framed Schematic Print", "FSP") {}
}
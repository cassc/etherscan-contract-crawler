// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: dillsOnOne
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    OOO    //
//           //
//           //
///////////////


contract OOO is ERC721Creator {
    constructor() ERC721Creator("dillsOnOne", "OOO") {}
}
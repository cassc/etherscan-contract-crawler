// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ART
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    ART    //
//           //
//           //
///////////////


contract ART is ERC721Creator {
    constructor() ERC721Creator("ART", "ART") {}
}
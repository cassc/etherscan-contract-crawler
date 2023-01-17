// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: brnski
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    fff    //
//           //
//           //
///////////////


contract brn is ERC721Creator {
    constructor() ERC721Creator("brnski", "brn") {}
}
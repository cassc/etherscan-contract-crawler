// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cullinan Legend
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    CLD    //
//           //
//           //
///////////////


contract CLD is ERC721Creator {
    constructor() ERC721Creator("Cullinan Legend", "CLD") {}
}
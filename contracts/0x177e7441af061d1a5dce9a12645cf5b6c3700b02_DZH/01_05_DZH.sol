// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DAVIDHORVATH
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    DZH    //
//           //
//           //
///////////////


contract DZH is ERC721Creator {
    constructor() ERC721Creator("DAVIDHORVATH", "DZH") {}
}
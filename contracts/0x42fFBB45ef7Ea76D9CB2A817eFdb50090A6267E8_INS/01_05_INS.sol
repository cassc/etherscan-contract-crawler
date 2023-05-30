// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Infinite Sprouts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    INS    //
//           //
//           //
///////////////


contract INS is ERC721Creator {
    constructor() ERC721Creator("Infinite Sprouts", "INS") {}
}
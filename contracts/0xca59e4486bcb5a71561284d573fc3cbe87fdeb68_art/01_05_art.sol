// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: literal art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    art    //
//           //
//           //
///////////////


contract art is ERC721Creator {
    constructor() ERC721Creator("literal art", "art") {}
}
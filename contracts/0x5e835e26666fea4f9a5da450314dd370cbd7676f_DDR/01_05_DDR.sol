// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Daydreamer
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    forsart    //
//               //
//               //
///////////////////


contract DDR is ERC721Creator {
    constructor() ERC721Creator("Daydreamer", "DDR") {}
}
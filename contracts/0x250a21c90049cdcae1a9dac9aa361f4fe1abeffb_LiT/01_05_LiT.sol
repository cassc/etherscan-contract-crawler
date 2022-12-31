// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lost in Translation
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    LITLABS    //
//               //
//               //
///////////////////


contract LiT is ERC721Creator {
    constructor() ERC721Creator("Lost in Translation", "LiT") {}
}
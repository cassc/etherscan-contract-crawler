// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ARMENIA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    ARMENIA    //
//               //
//               //
///////////////////


contract Armenia is ERC721Creator {
    constructor() ERC721Creator("ARMENIA", "Armenia") {}
}
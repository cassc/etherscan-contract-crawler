// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VISIONS.
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    x < > x    //
//               //
//               //
///////////////////


contract vsn is ERC721Creator {
    constructor() ERC721Creator("VISIONS.", "vsn") {}
}
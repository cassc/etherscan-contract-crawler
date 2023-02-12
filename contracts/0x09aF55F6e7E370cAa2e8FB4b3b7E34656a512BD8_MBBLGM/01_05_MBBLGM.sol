// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mubblegum
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    MUBBLES    //
//               //
//               //
///////////////////


contract MBBLGM is ERC721Creator {
    constructor() ERC721Creator("Mubblegum", "MBBLGM") {}
}
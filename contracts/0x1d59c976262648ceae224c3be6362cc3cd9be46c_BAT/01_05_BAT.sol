// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ipblat
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    smolBAT    //
//               //
//               //
///////////////////


contract BAT is ERC721Creator {
    constructor() ERC721Creator("ipblat", "BAT") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CONTE74
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    CONTE74    //
//               //
//               //
///////////////////


contract C74 is ERC721Creator {
    constructor() ERC721Creator("CONTE74", "C74") {}
}
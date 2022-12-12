// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Christmas Cat Girl
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    (´・ω・`)    //
//               //
//               //
///////////////////


contract CCG is ERC721Creator {
    constructor() ERC721Creator("Christmas Cat Girl", "CCG") {}
}
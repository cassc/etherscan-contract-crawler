// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tiny Art Creations
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    TinyArt    //
//               //
//               //
///////////////////


contract TNART is ERC1155Creator {
    constructor() ERC1155Creator("Tiny Art Creations", "TNART") {}
}
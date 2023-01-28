// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: shrnkld
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    shrnkld    //
//               //
//               //
///////////////////


contract shrnkld is ERC721Creator {
    constructor() ERC721Creator("shrnkld", "shrnkld") {}
}
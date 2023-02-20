// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: STONED SANTA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    CP 420     //
//               //
//               //
///////////////////


contract CP420 is ERC721Creator {
    constructor() ERC721Creator("STONED SANTA", "CP420") {}
}
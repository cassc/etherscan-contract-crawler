// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: vrenarn
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    vrenarn    //
//               //
//               //
///////////////////


contract vrenarn is ERC721Creator {
    constructor() ERC721Creator("vrenarn", "vrenarn") {}
}
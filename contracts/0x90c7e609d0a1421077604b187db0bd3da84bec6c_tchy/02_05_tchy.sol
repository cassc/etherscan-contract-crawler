// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tachyon
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    tachyon    //
//               //
//               //
///////////////////


contract tchy is ERC721Creator {
    constructor() ERC721Creator("tachyon", "tchy") {}
}
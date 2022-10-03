// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: dfc
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    edg cdf    //
//               //
//               //
///////////////////


contract edg is ERC721Creator {
    constructor() ERC721Creator("dfc", "edg") {}
}
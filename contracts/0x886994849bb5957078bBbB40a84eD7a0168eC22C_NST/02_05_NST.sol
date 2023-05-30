// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: neverset
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    nst    //
//           //
//           //
///////////////


contract NST is ERC721Creator {
    constructor() ERC721Creator("neverset", "NST") {}
}
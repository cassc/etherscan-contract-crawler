// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Small Drop
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    hhh    //
//           //
//           //
///////////////


contract SD is ERC721Creator {
    constructor() ERC721Creator("Small Drop", "SD") {}
}
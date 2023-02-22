// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: X/X
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    x/x    //
//           //
//           //
///////////////


contract xx is ERC1155Creator {
    constructor() ERC1155Creator("X/X", "xx") {}
}
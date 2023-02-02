// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gunkies
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    LFG    //
//           //
//           //
///////////////


contract GUNK is ERC1155Creator {
    constructor() ERC1155Creator("Gunkies", "GUNK") {}
}
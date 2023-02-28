// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RVT1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    RVT    //
//           //
//           //
///////////////


contract RVT is ERC1155Creator {
    constructor() ERC1155Creator("RVT1155", "RVT") {}
}
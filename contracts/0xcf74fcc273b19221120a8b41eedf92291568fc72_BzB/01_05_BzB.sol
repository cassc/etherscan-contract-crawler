// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blazar 0 Club
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    BzB    //
//           //
//           //
///////////////


contract BzB is ERC1155Creator {
    constructor() ERC1155Creator("Blazar 0 Club", "BzB") {}
}
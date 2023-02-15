// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fluid - Ordinals | Ticket
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    FLD    //
//           //
//           //
///////////////


contract FLD is ERC721Creator {
    constructor() ERC721Creator("Fluid - Ordinals | Ticket", "FLD") {}
}
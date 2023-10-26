// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NEW GENESIS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    ART    //
//           //
//           //
///////////////


contract GEN is ERC721Creator {
    constructor() ERC721Creator("NEW GENESIS", "GEN") {}
}
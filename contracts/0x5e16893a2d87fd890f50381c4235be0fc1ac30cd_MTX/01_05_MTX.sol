// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MATRIX by Mikasa
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    MTX    //
//           //
//           //
///////////////


contract MTX is ERC721Creator {
    constructor() ERC721Creator("MATRIX by Mikasa", "MTX") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Puyallup
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    LAM    //
//           //
//           //
///////////////


contract PUY is ERC721Creator {
    constructor() ERC721Creator("Puyallup", "PUY") {}
}
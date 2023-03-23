// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pop Punk Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    Yo!    //
//           //
//           //
///////////////


contract POP is ERC721Creator {
    constructor() ERC721Creator("Pop Punk Editions", "POP") {}
}
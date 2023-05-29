// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cryptopainter
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    cp     //
//           //
//           //
///////////////


contract CP23 is ERC721Creator {
    constructor() ERC721Creator("cryptopainter", "CP23") {}
}
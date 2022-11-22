// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: General Bull Cartoons
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    ///    //
//           //
//           //
///////////////


contract GBC is ERC721Creator {
    constructor() ERC721Creator("General Bull Cartoons", "GBC") {}
}
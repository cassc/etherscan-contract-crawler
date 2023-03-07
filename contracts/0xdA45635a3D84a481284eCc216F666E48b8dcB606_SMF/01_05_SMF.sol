// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shiitake Mushroom Farms
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    SMF    //
//           //
//           //
///////////////


contract SMF is ERC721Creator {
    constructor() ERC721Creator("Shiitake Mushroom Farms", "SMF") {}
}
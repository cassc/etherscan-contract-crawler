// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SHAPEPE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    SHAPEPE    //
//               //
//               //
///////////////////


contract SPPP is ERC721Creator {
    constructor() ERC721Creator("SHAPEPE", "SPPP") {}
}
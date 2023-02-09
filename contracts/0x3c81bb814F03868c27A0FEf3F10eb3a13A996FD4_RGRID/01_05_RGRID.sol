// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rainbow grids
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    lbn21    //
//             //
//             //
/////////////////


contract RGRID is ERC721Creator {
    constructor() ERC721Creator("Rainbow grids", "RGRID") {}
}
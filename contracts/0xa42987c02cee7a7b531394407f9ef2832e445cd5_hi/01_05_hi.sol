// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tiltle
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    hello    //
//             //
//             //
/////////////////


contract hi is ERC721Creator {
    constructor() ERC721Creator("tiltle", "hi") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crossmint Test ERC721
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    A B C    //
//             //
//             //
/////////////////


contract TEST is ERC721Creator {
    constructor() ERC721Creator("Crossmint Test ERC721", "TEST") {}
}
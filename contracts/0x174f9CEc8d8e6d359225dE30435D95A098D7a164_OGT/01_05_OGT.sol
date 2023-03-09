// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ord Geese Test
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    a    //
//         //
//         //
/////////////


contract OGT is ERC721Creator {
    constructor() ERC721Creator("Ord Geese Test", "OGT") {}
}
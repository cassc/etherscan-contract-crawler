// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - Pepe Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Checks - pepe edition    //
//                             //
//                             //
/////////////////////////////////


contract ChecksP is ERC721Creator {
    constructor() ERC721Creator("Checks - Pepe Edition", "ChecksP") {}
}
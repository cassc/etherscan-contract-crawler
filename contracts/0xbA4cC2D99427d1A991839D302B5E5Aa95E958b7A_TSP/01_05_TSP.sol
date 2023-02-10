// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tetra's Special Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Tetra's Special Art!!    //
//                             //
//                             //
/////////////////////////////////


contract TSP is ERC721Creator {
    constructor() ERC721Creator("Tetra's Special Art", "TSP") {}
}
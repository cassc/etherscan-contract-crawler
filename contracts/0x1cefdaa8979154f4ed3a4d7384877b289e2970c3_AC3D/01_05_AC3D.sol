// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - 3D Pepe Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//                         //
//    /\ ( | |) | ( /\     //
//                         //
//                         //
//                         //
//                         //
/////////////////////////////


contract AC3D is ERC721Creator {
    constructor() ERC721Creator("Checks - 3D Pepe Edition", "AC3D") {}
}
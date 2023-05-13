// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepemolism
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    pepemolism.    //
//                   //
//                   //
///////////////////////


contract PPMM is ERC721Creator {
    constructor() ERC721Creator("Pepemolism", "PPMM") {}
}
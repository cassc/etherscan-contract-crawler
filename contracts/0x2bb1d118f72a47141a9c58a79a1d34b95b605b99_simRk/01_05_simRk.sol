// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SimpsonRock
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    simpsonrock    //
//                   //
//                   //
///////////////////////


contract simRk is ERC721Creator {
    constructor() ERC721Creator("SimpsonRock", "simRk") {}
}
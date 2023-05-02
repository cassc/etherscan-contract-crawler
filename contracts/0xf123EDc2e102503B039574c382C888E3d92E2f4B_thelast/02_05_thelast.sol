// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Last BC Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    With love, BC.    //
//                      //
//                      //
//////////////////////////


contract thelast is ERC721Creator {
    constructor() ERC721Creator("The Last BC Collection", "thelast") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Taryn Treisman Genesis
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Taryn Treisman Art    //
//                          //
//                          //
//////////////////////////////


contract TCT is ERC721Creator {
    constructor() ERC721Creator("Taryn Treisman Genesis", "TCT") {}
}
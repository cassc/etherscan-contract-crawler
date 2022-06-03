// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Magisterium Genesis Pass
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    magic lies within.    //
//                          //
//                          //
//////////////////////////////


contract MGP is ERC721Creator {
    constructor() ERC721Creator("Magisterium Genesis Pass", "MGP") {}
}
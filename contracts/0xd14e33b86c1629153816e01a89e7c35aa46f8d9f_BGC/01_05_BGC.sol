// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bizzle's Gutter Checks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    GCG Tirbute to Jack Butcher and Checks    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract BGC is ERC1155Creator {
    constructor() ERC1155Creator("Bizzle's Gutter Checks", "BGC") {}
}
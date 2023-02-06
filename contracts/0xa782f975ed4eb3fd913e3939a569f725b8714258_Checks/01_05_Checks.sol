// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - Banana Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    This Banana may or may not be notable.    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract Checks is ERC721Creator {
    constructor() ERC721Creator("Checks - Banana Edition", "Checks") {}
}
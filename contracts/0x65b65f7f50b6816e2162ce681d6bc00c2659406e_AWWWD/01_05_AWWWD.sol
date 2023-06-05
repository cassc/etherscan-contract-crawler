// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Wonderful Way with Dragons - Poster Image
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    "Difficulties mastered are opportunities won." - Churchill    //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract AWWWD is ERC1155Creator {
    constructor() ERC1155Creator("A Wonderful Way with Dragons - Poster Image", "AWWWD") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Drawings by Conlan
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    Hello,                                               //
//                                                         //
//    These are some drawings taken from my sketchbook.    //
//                                                         //
//    Hope you enjoy!                                      //
//                                                         //
//    Conlan Rios                                          //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract DRAWING is ERC1155Creator {
    constructor() ERC1155Creator("Drawings by Conlan", "DRAWING") {}
}
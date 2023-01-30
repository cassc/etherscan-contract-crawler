// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ReVersoX
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//    RRRR      V     V                 X   X     //
//    R   R     V     V                  X X      //
//    RRRR  eee  V   V  eee rrr  ss ooo   X       //
//    R R   e e   V V   e e r    s  o o  X X      //
//    R  RR ee     V    ee  r   ss  ooo X   X     //
//                                                //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract RVX is ERC1155Creator {
    constructor() ERC1155Creator("ReVersoX", "RVX") {}
}
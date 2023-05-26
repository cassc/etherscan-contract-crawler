// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jay Olson B-Sides
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//        J            OOO  l               BBBB       SSS        d             //
//        J           O   O l               B   B     S     ii    d             //
//        J  aa y  y  O   O l  ss ooo nnn   BBBB  ---  SSS      ddd eee  ss     //
//    J   J a a y  y  O   O l  s  o o n  n  B   B         S ii d  d e e  s      //
//     JJJ  aaa  yyy   OOO  l ss  ooo n  n  BBBB      SSSS  ii  ddd ee  ss      //
//                 y                                                            //
//              yyy                                                             //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract JOBSD is ERC721Creator {
    constructor() ERC721Creator("Jay Olson B-Sides", "JOBSD") {}
}
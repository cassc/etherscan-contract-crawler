// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AIR23
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//    AIR23 is                                -                          //
//                                                                       //
//                                                                       //
//                 a contract                                            //
//                                                                       //
//    intended to                  *            make monthly airdrops    //
//                                                                       //
//                                                                       //
//                                                                       //
//    every                                                              //
//                                                                       //
//                             23rd day                    -             //
//               +                                                       //
//                                                                       //
//                                                                       //
//    to Tormius                 ·               1/1 collectors. /       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract AIR23 is ERC1155Creator {
    constructor() ERC1155Creator("AIR23", "AIR23") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MFERingers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                              //
//                                                                                                              //
//    M"""""`'"""`YM MM""""""""`M MM""""""""`M MM"""""""`MM oo                                                  //
//    M  mm.  mm.  M MM  mmmmmmmM MM  mmmmmmmM MM  mmmm,  M                                                     //
//    M  MMM  MMM  M M'      MMMM M`      MMMM M'        .M dP 88d888b. .d8888b. .d8888b. 88d888b. .d8888b.     //
//    M  MMM  MMM  M MM  MMMMMMMM MM  MMMMMMMM MM  MMMb. "M 88 88'  `88 88'  `88 88ooood8 88'  `88 Y8ooooo.     //
//    M  MMM  MMM  M MM  MMMMMMMM MM  MMMMMMMM MM  MMMMM  M 88 88    88 88.  .88 88.  ... 88             88     //
//    M  MMM  MMM  M MM  MMMMMMMM MM        .M MM  MMMMM  M dP dP    dP `8888P88 `88888P' dP       `88888P'     //
//    MMMMMMMMMMMMMM MMMMMMMMMMMM MMMMMMMMMMMM MMMMMMMMMMMM                  .88                                //
//                                                                       d8888P                                 //
//                                                                                                              //
//                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MFRGRS is ERC721Creator {
    constructor() ERC721Creator("MFERingers", "MFRGRS") {}
}
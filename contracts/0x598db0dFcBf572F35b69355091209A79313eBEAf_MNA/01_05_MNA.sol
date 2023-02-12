// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MOSSSART - new arts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//    MM    MM  OOOOO   SSSSS   SSSSS   SSSSS    AAA   RRRRRR  TTTTTTT     //
//    MMM  MMM OO   OO SS      SS      SS       AAAAA  RR   RR   TTT       //
//    MM MM MM OO   OO  SSSSS   SSSSS   SSSSS  AA   AA RRRRRR    TTT       //
//    MM    MM OO   OO      SS      SS      SS AAAAAAA RR  RR    TTT       //
//    MM    MM  OOOO0   SSSSS   SSSSS   SSSSS  AA   AA RR   RR   TTT       //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract MNA is ERC721Creator {
    constructor() ERC721Creator("MOSSSART - new arts", "MNA") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: literallAI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//    88  88                                              88  88         db         88      //
//    88  ""    ,d                                        88  88        d88b        88      //
//    88        88                                        88  88       d8'`8b       88      //
//    88  88  MM88MMM  ,adPPYba,  8b,dPPYba,  ,adPPYYba,  88  88      d8'  `8b      88      //
//    88  88    88    a8P_____88  88P'   "Y8  ""     `Y8  88  88     d8YaaaaY8b     88      //
//    88  88    88    8PP"""""""  88          ,adPPPPP88  88  88    d8""""""""8b    88      //
//    88  88    88,   "8b,   ,aa  88          88,    ,88  88  88   d8'        `8b   88      //
//    88  88    "Y888  `"Ybbd8"'  88          `"8bbdP"Y8  88  88  d8'          `8b  88      //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract LAI is ERC721Creator {
    constructor() ERC721Creator("literallAI", "LAI") {}
}
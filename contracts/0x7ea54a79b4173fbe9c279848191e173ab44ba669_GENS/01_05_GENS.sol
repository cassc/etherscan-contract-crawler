// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Genesis
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//                                                                               //
//                           88                                                  //
//                           88                                                  //
//                           88                                                  //
//     ,adPPYba, 8b       d8 88,dPPYba,   ,adPPYba,  8b,dPPYba,  ,adPPYb,d8      //
//    a8"     "" `8b     d8' 88P'    "8a a8"     "8a 88P'   "Y8 a8"    `Y88      //
//    8b          `8b   d8'  88       d8 8b       d8 88         8b       88      //
//    "8a,   ,aa   `8b,d8'   88b,   ,a8" "8a,   ,a8" 88         "8a,   ,d88      //
//     `"Ybbd8"'     Y88'    8Y"Ybbd8"'   `"YbbdP"'  88          `"YbbdP"Y8      //
//                   d8'                                         aa,    ,88      //
//                  d8'                                           "Y8bbdP"       //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract GENS is ERC721Creator {
    constructor() ERC721Creator("Genesis", "GENS") {}
}
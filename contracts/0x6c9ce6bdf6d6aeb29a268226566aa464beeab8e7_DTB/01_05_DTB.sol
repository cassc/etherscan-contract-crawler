// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DARE TO BE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//    88                                                                               //
//                88                                            ,d                     //
//                88                                            88                     //
//        ,adPPYb,88  ,adPPYYba,  8b,dPPYba,   ,adPPYba,      MM88MMM  ,adPPYba,       //
//       a8"    `Y88  ""     `Y8  88P'   "Y8  a8P_____88        88    a8"     "8a      //
//       8b       88  ,adPPPPP88  88          8PP"""""""        88    8b       d8      //
//       "8a,   ,d88  88,    ,88  88          "8b,   ,aa        88,   "8a,   ,a8"      //
//        `"8bbdP"Y8  `"8bbdP"Y8  88           `"Ybbd8"'        "Y888  `"YbbdP"'       //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                               88                                                    //
//                               88                                                    //
//                               88                                                    //
//                               88,dPPYba,    ,adPPYba,                               //
//                               88P'    "8a  a8P_____88                               //
//                               88       d8  8PP"""""""                               //
//                               88b,   ,a8"  "8b,   ,aa                               //
//                               8Y"Ybbd8"'    `"Ybbd8"'                               //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract DTB is ERC721Creator {
    constructor() ERC721Creator("DARE TO BE", "DTB") {}
}
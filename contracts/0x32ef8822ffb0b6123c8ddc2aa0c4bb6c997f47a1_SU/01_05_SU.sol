// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sakeshart Universe
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//                           88                               88                                                //
//                           88                               88                                     ,d         //
//                           88                               88                                     88         //
//    ,adPPYba,  ,adPPYYba,  88   ,d8   ,adPPYba,  ,adPPYba,  88,dPPYba,   ,adPPYYba,  8b,dPPYba,  MM88MMM      //
//    I8[    ""  ""     `Y8  88 ,a8"   a8P_____88  I8[    ""  88P'    "8a  ""     `Y8  88P'   "Y8    88         //
//     `"Y8ba,   ,adPPPPP88  8888[     8PP"""""""   `"Y8ba,   88       88  ,adPPPPP88  88            88         //
//    aa    ]8I  88,    ,88  88`"Yba,  "8b,   ,aa  aa    ]8I  88       88  88,    ,88  88            88,        //
//    `"YbbdP"'  `"8bbdP"Y8  88   `Y8a  `"Ybbd8"'  `"YbbdP"'  88       88  `"8bbdP"Y8  88            "Y888      //
//                                                                                                              //
//                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SU is ERC1155Creator {
    constructor() ERC1155Creator("Sakeshart Universe", "SU") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XCRAPPY
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//     ,adPPYba, 8b,dPPYba, ,adPPYYba, 8b,dPPYba,       //
//    a8"     "" 88P'   "Y8 ""     `Y8 88P'    "8a      //
//    8b         88         ,adPPPPP88 88       d8      //
//    "8a,   ,aa 88         88,    ,88 88b,   ,a8"      //
//     `"Ybbd8"' 88         `"8bbdP"Y8 88`YbbdP"'       //
//                                     88               //
//                                     88               //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract XCPY is ERC721Creator {
    constructor() ERC721Creator("XCRAPPY", "XCPY") {}
}
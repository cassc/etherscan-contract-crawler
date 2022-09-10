// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dark Light
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//    88888888ba,                         88             //
//    88      `"8b                        88             //
//    88        `8b                       88             //
//    88         88 ,adPPYYba, 8b,dPPYba, 88   ,d8       //
//    88         88 ""     `Y8 88P'   "Y8 88 ,a8"        //
//    88         8P ,adPPPPP88 88         8888[          //
//    88      .a8P  88,    ,88 88         88`"Yba,       //
//    88888888Y"'   `"8bbdP"Y8 88         88   `Y8a      //
//                                                       //
//                                                       //
//                                                       //
//    88          88             88                      //
//    88          ""             88           ,d         //
//    88                         88           88         //
//    88          88  ,adPPYb,d8 88,dPPYba, MM88MMM      //
//    88          88 a8"    `Y88 88P'    "8a  88         //
//    88          88 8b       88 88       88  88         //
//    88          88 "8a,   ,d88 88       88  88,        //
//    88888888888 88  `"YbbdP"Y8 88       88  "Y888      //
//                    aa,    ,88                         //
//                     "Y8bbdP"                          //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract ASTRO is ERC721Creator {
    constructor() ERC721Creator("Dark Light", "ASTRO") {}
}
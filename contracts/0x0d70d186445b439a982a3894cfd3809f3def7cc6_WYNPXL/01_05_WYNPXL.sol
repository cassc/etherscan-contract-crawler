// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: birth of a pixel
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    888       888                       //
//    888   o   888                       //
//    888  d8b  888                       //
//    888 d888b 888 888  888 88888b.      //
//    888d88888b888 888  888 888 "88b     //
//    88888P Y88888 888  888 888  888     //
//    8888P   Y8888 Y88b 888 888  888     //
//    888P     Y888  "Y88888 888  888     //
//                       888              //
//                  Y8b d88P              //
//                   "Y88P"               //
//                                        //
//                                        //
////////////////////////////////////////////


contract WYNPXL is ERC721Creator {
    constructor() ERC721Creator("birth of a pixel", "WYNPXL") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Baha's breakfast artworks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//     .d88b. 88888b.d88b.      //
//    d88P"88b888 "888 "88b     //
//    888  888888  888  888     //
//    Y88b 888888  888  888     //
//     "Y88888888  888  888     //
//         888                  //
//    Y8b d88P                  //
//     "Y88P"                   //
//                              //
//                              //
//////////////////////////////////


contract BBA is ERC721Creator {
    constructor() ERC721Creator("Baha's breakfast artworks", "BBA") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Everynights
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    Addie Wagenknecht                      //
//    https://www.placesiveneverbeen.com/    //
//    2023                                   //
//    Evertnights: Night 0                   //
//                                           //
//                                           //
///////////////////////////////////////////////


contract Day0 is ERC721Creator {
    constructor() ERC721Creator("Everynights", "Day0") {}
}
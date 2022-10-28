// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chromatic Abstractions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//    ...                                                                                  //
//    ...                                                                                  //
//    ...Look.                                                                             //
//    ...                                                                                  //
//    ...There isn't anything interesting here.  ASCII art isn't interesting.              //
//    ...                                                                                  //
//    ...                                                                                  //
//    ...I literally deal with color and shapes as they relate to our human experience.    //
//    ...                                                                                  //
//    ...                                                                                  //
//    ...                                                                                  //
//    ...How is this ASCII art supposed to help that effort in any way?                    //
//    ...                                                                                  //
//    ...                                                                                  //
//    ...   "Chromatic Abstrations" - Art by Steve Walasavage                              //
//    ...                                                                                  //
//    ...                                                                                  //
//    ...                                                                                  //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract CHROMATIC is ERC721Creator {
    constructor() ERC721Creator("Chromatic Abstractions", "CHROMATIC") {}
}
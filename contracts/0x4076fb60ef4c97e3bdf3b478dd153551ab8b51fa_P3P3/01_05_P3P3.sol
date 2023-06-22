// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: P3P3 THE CLUB
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    ThugManStudio                      //
//                                       //
//    Parody | Fake art | Sexy & Weed    //
//                                       //
//    THE WORLD IS GOOD .                //
//                                       //
//                                       //
///////////////////////////////////////////


contract P3P3 is ERC721Creator {
    constructor() ERC721Creator("P3P3 THE CLUB", "P3P3") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: -dash
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//    -dash is a crypto music startup co-founded by Ashot Danielyan.    //
//                                                                      //
//    Ashot Danielyan is a musician, composer and founder of a new      //
//    music genre – Angelic Piano. He also composes music in a          //
//    variety of other genres such as Classical, Ambient,               //
//    New Age and Experimental music.                                   //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract DASH is ERC721Creator {
    constructor() ERC721Creator("-dash", "DASH") {}
}
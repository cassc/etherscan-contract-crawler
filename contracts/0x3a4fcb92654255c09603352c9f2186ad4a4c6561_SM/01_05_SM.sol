// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sangfroid Mentation
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                      //
//                                                                                                                                                      //
//    "Sangfroid Mentation" Collection by Brendan S Bigney (The Nuclear Cowboy), Marine Corps Veteran, photographer, and Multi-Award-Winning Author.    //
//                                                                                                                                                      //
//    In collaboration with Kaleidoklops, artist, photographer, and Marine Corps Veteran.                                                               //
//                                                                                                                                                      //
//    nuclearcowboy.com                                                                                                                                 //
//                                                                                                                                                      //
//                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SM is ERC721Creator {
    constructor() ERC721Creator("Sangfroid Mentation", "SM") {}
}
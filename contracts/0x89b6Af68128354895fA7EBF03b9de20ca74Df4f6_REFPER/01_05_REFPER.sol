// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reflections on Perspective
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//    Emo Ryan is a London based filmmaker, photographer, and street artist.    //
//                                                                              //
//    Punk's not dead. Neither are you.                                         //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract REFPER is ERC721Creator {
    constructor() ERC721Creator("Reflections on Perspective", "REFPER") {}
}
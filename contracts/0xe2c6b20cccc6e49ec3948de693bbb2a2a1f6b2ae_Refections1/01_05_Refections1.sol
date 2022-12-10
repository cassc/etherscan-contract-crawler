// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reflections I
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                       //
//                                                                                                       //
//    Reflections is a series of limited editions of wildlife images with reflections.                   //
//    I fell in love with capturing wildlife images with their reflection the first time i saw a lion    //
//    drink water from a waterhole in Kgalgadi transfrontier park. It just added a completely            //
//    different dynamic to the composition.                                                              //
//                                                                                                       //
//    Finding big cats in wildlife is quite difficult. Finding them drinking water is even more          //
//    difficult. Capturing the perfect reflection shot is very rare. I was very lucky                    //
//    to have captured this shot of a lion cub drinking water in Gir national park.                      //
//    It's a treasured moment and is something that i will always remember. This image                   //
//    will be first of 4 limited images to be released as part of reflection series.                     //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Refections1 is ERC721Creator {
    constructor() ERC721Creator("Reflections I", "Refections1") {}
}
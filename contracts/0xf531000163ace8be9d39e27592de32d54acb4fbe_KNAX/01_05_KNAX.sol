// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ROADSIDE GEWGAW
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//    {Illustrated record of knickknacks discovered roadside                               //
//    during morning jogs.}                                                                //
//                                                                                         //
//    *Found objects are left to the landscape (but not entirely), no matter               //
//    how precious or toxic to the environment.                                            //
//    They are witnessed and undergo a caloric imagery transcription process,              //
//    very complicated.                                                                    //
//    I say not entirely as I take their calories & feed you, the viewer, abstract         //
//    glitch. Some of these drawn up objects may resemble their original form but most     //
//    will not. Which is why I include descriptive text. It might not seem like it, but    //
//    I really do want you to know what I witnessed on my run this morning.                //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract KNAX is ERC721Creator {
    constructor() ERC721Creator("ROADSIDE GEWGAW", "KNAX") {}
}
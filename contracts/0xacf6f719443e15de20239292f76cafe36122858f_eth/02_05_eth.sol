// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My Happiness
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//    Happiness is like a beautiful flowers that we met every day.                              //
//    Happiness resides in where i feel peaceful.                                               //
//    I do what i love and that thing i called my true happiness.                               //
//    And my happiness is to stay here and create art everyday also learning everything new     //
//    likes a bloooming flowers.                                                                //
//                                                                                              //
//    Process : Krita+Photoshop +Dalle +Stable Diffusion.                                       //
//    Create By Folky                                                                           //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////


contract eth is ERC721Creator {
    constructor() ERC721Creator("My Happiness", "eth") {}
}
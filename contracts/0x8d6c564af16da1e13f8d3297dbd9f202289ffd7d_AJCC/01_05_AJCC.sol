// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cazandocielos
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//    Despite the constant episodes of depression coming and going from my life, specially the past few years, I consider myself lucky; I've found in photography a door to escape to another reality.                                         //
//                                                                                                                                                                                                                                             //
//    On this reality, I get to see places I've never thought they existed. I get to enjoy the trill of a chase. I get to feel free. From the world. From my own thoughts. From everything.                                                    //
//                                                                                                                                                                                                                                             //
//    I live in a dream, and these are my creations.                                                                                                                                                                                           //
//                                                                                                                                                                                                                                             //
//    =                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                             //
//    Yeah, I know what you'd say, Alfredo, don't be such a positive guy, well, truth be told, I've had encounters with armed drug members.                                                                                                    //
//                                                                                                                                                                                                                                             //
//    Unfortunately, I get to chase these hidden dream lands in an area controlled by drug cartels, and it's not impossible to get these encounters, where I have to explain what I am doing while some dude is aiming an AK-47 to my head.    //
//                                                                                                                                                                                                                                             //
//    The photos minted on this contract are rather impossible to make, and every place I visit, is kind of a one time opportunity, so, some of them, don't get the chance to get a revisit.                                                   //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AJCC is ERC721Creator {
    constructor() ERC721Creator("cazandocielos", "AJCC") {}
}
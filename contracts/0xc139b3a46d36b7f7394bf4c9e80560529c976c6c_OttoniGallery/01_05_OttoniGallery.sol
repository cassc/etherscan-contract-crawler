// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Paty Ottoni
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                     //
//                                                                                                     //
//    Fine Art Photography...                                                                          //
//    I'm...                                                                                           //
//    I'am what I see...                                                                               //
//    I'am what I feel...                                                                              //
//    I'am what I do...                                                                                //
//    Through my lenses I freeze a slice of time where my memories and experiences are installed...    //
//    Images that are in my inner universe that I print using technology...                            //
//    These images blend with the real...                                                              //
//    And this real is in which dimension?!...                                                         //
//    In what each one can see?!...                                                                    //
//    That's the concept...                                                                            //
//    Come find out through my eyes...                                                                 //
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OttoniGallery is ERC721Creator {
    constructor() ERC721Creator("Paty Ottoni", "OttoniGallery") {}
}
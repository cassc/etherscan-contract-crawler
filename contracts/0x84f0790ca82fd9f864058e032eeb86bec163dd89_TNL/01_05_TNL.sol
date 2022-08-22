// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Northen Lights
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                    //
//    Framing the northen lights as been one of my dreams as a photographer, when i was a kid i used to see this amazing frames from this misterious green lights that were visible during the night and this caught my atention and curiosity during this early years of my life.    //
//    Recently i had the chance to travel to Alaska several times and the dream just came alive...at least the hopes of framing this amazing show that nature can provide.                                                                                                            //
//    But the task is not easy... It´s hard to predict when it will show, we have to consider several factors as weather condition, intensity of the solar storm and the timming that will hit the atmosfere.                                                                         //
//    This final result it wasn´t what was expecting to achieve but i am happy to share this small part of my dream with you...                                                                                                                                                       //
//    NJOYYYYYYY                                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TNL is ERC721Creator {
    constructor() ERC721Creator("The Northen Lights", "TNL") {}
}
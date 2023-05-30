// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Magical Forest
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    MAGICAL FOREST                                        //
//                                                          //
//    Listen up, I got a story to tell                      //
//    'Bout a magical forest, where everything was swell    //
//    Trees and bushes, animals too                         //
//    Living together in harmony, like a crew.              //
//                                                          //
//    This forest was a metaphor for wisdom                 //
//    Where all creatures lived in a system                 //
//    Of respect and care, for each other and nature        //
//    A lesson we should all learn, for sure.               //
//                                                          //
//    4k ◦ 3240x2160 px                                     //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract FOREST is ERC721Creator {
    constructor() ERC721Creator("Magical Forest", "FOREST") {}
}
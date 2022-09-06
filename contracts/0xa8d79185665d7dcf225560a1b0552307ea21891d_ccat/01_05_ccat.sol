// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: climbing cat
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                 //
//                                                                                                 //
//     ██████╗██╗     ██╗███╗   ███╗██████╗ ██╗███╗   ██╗ ██████╗      ██████╗ █████╗ ████████╗    //
//    ██╔════╝██║     ██║████╗ ████║██╔══██╗██║████╗  ██║██╔════╝     ██╔════╝██╔══██╗╚══██╔══╝    //
//    ██║     ██║     ██║██╔████╔██║██████╔╝██║██╔██╗ ██║██║  ███╗    ██║     ███████║   ██║       //
//    ██║     ██║     ██║██║╚██╔╝██║██╔══██╗██║██║╚██╗██║██║   ██║    ██║     ██╔══██║   ██║       //
//    ╚██████╗███████╗██║██║ ╚═╝ ██║██████╔╝██║██║ ╚████║╚██████╔╝    ╚██████╗██║  ██║   ██║       //
//     ╚═════╝╚══════╝╚═╝╚═╝     ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝      ╚═════╝╚═╝  ╚═╝   ╚═╝       //
//                                                                                                 //
//    by darknoov                                                                                  //
//    orginal artwork size ; 5x5                                                                   //
//    part of instincthead collection  17 / part 4                                                 //
//                                                                                                 //
//     in essence, the state of feeling transformed into action.                                   //
//     is x. are the masters of this culture.                                                      //
//                                                                                                 //
//                                                                                                 //
//    When I was in close contact with street writing,                                             //
//    I drew this piece inspired by a girlfriend                                                   //
//    I liked who asked me to take photos of buildings from a height.                              //
//                                                                                                 //
//                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////


contract ccat is ERC721Creator {
    constructor() ERC721Creator("climbing cat", "ccat") {}
}
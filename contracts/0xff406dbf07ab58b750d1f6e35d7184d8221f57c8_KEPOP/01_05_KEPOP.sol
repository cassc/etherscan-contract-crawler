// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: POP ART
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//    ooooooooo.     .oooooo.   ooooooooo.            .o.       ooooooooo.   ooooooooooooo     //
//    `888   `Y88.  d8P'  `Y8b  `888   `Y88.         .888.      `888   `Y88. 8'   888   `8     //
//     888   .d88' 888      888  888   .d88'        .8"888.      888   .d88'      888          //
//     888ooo88P'  888      888  888ooo88P'        .8' `888.     888ooo88P'       888          //
//     888         888      888  888              .88ooo8888.    888`88b.         888          //
//     888         `88b    d88'  888             .8'     `888.   888  `88b.       888          //
//    o888o         `Y8bood8P'  o888o           o88o     o8888o o888o  o888o     o888o         //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract KEPOP is ERC721Creator {
    constructor() ERC721Creator("POP ART", "KEPOP") {}
}
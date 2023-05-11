// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OlgaGlith
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//      .oooooo.   oooo                         .oooooo.    oooo   o8o      .   oooo            //
//     d8P'  `Y8b  `888                        d8P'  `Y8b   `888   `"'    .o8   `888            //
//    888      888  888   .oooooooo  .oooo.   888            888  oooo  .o888oo  888 .oo.       //
//    888      888  888  888' `88b  `P  )88b  888            888  `888    888    888P"Y88b      //
//    888      888  888  888   888   .oP"888  888     ooooo  888   888    888    888   888      //
//    `88b    d88'  888  `88bod8P'  d8(  888  `88.    .88'   888   888    888 .  888   888      //
//     `Y8bood8P'  o888o `8oooooo.  `Y888""8o  `Y8bood8P'   o888o o888o   "888" o888o o888o     //
//                       d"     YD                                                              //
//                       "Y88888P'                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////


contract e2e4 is ERC721Creator {
    constructor() ERC721Creator("OlgaGlith", "e2e4") {}
}
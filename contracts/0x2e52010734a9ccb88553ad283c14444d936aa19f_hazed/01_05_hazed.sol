// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: hazed 1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//                                                              //
//    oooo                                             .o8      //
//    `888                                            "888      //
//     888 .oo.    .oooo.     oooooooo  .ooooo.   .oooo888      //
//     888P"Y88b  `P  )88b   d'""7d8P  d88' `88b d88' `888      //
//     888   888   .oP"888     .d8P'   888ooo888 888   888      //
//     888   888  d8(  888   .d8P'  .P 888    .o 888   888      //
//    o888o o888o `Y888""8o d8888888P  `Y8bod8P' `Y8bod88P"     //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract hazed is ERC721Creator {
    constructor() ERC721Creator("hazed 1/1", "hazed") {}
}
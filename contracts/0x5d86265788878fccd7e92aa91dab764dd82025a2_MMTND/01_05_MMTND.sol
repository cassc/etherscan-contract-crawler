// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Memetendo
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                   //
//                                                                                                                   //
//                                                                .                               .o8                //
//                                                              .o8                              "888                //
//    ooo. .oo.  .oo.    .ooooo.  ooo. .oo.  .oo.    .ooooo.  .o888oo  .ooooo.  ooo. .oo.    .oooo888   .ooooo.      //
//    `888P"Y88bP"Y88b  d88' `88b `888P"Y88bP"Y88b  d88' `88b   888   d88' `88b `888P"Y88b  d88' `888  d88' `88b     //
//     888   888   888  888ooo888  888   888   888  888ooo888   888   888ooo888  888   888  888   888  888   888     //
//     888   888   888  888    .o  888   888   888  888    .o   888 . 888    .o  888   888  888   888  888   888     //
//    o888o o888o o888o `Y8bod8P' o888o o888o o888o `Y8bod8P'   "888" `Y8bod8P' o888o o888o `Y8bod88P" `Y8bod8P'     //
//                                                                                                                   //
//                                                                                                                   //
//                                                                                                                   //
//    Memetendo - by Messhup                                                                                         //
//                                                                                                                   //
//                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MMTND is ERC1155Creator {
    constructor() ERC1155Creator("Memetendo", "MMTND") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RAREstacks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//    ooooooooo.         .o.       ooooooooo.   oooooooooooo              .                       oooo                     //
//    `888   `Y88.      .888.      `888   `Y88. `888'     `8            .o8                       `888                     //
//     888   .d88'     .8"888.      888   .d88'  888          .oooo.o .o888oo  .oooo.    .ooooo.   888  oooo   .oooo.o     //
//     888ooo88P'     .8' `888.     888ooo88P'   888oooo8    d88(  "8   888   `P  )88b  d88' `"Y8  888 .8P'   d88(  "8     //
//     888`88b.      .88ooo8888.    888`88b.     888    "    `"Y88b.    888    .oP"888  888        888888.    `"Y88b.      //
//     888  `88b.   .8'     `888.   888  `88b.   888       o o.  )88b   888 . d8(  888  888   .o8  888 `88b.  o.  )88b     //
//    o888o  o888o o88o     o8888o o888o  o888o o888ooooood8 8""888P'   "888" `Y888""8o `Y8bod8P' o888o o888o 8""888P'     //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract rarestacks is ERC721Creator {
    constructor() ERC721Creator("RAREstacks", "rarestacks") {}
}
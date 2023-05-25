// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Arsonic Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//                                                                                   //
//          .o.                                                o8o                   //
//         .888.                                               `"'                   //
//        .8"888.     oooo d8b  .oooo.o  .ooooo.  ooo. .oo.   oooo   .ooooo.         //
//       .8' `888.    `888""8P d88(  "8 d88' `88b `888P"Y88b  `888  d88' `"Y8        //
//      .88ooo8888.    888     `"Y88b.  888   888  888   888   888  888              //
//     .8'     `888.   888     o.  )88b 888   888  888   888   888  888   .o8        //
//    o88o     o8888o d888b    8""888P' `Y8bod8P' o888o o888o o888o `Y8bod8P'        //
//                                                                                   //
//                                                                                   //
//                                                                                   //
//    oooooooooooo       .o8   o8o      .    o8o                                     //
//    `888'     `8      "888   `"'    .o8    `"'                                     //
//     888          .oooo888  oooo  .o888oo oooo   .ooooo.  ooo. .oo.    .oooo.o     //
//     888oooo8    d88' `888  `888    888   `888  d88' `88b `888P"Y88b  d88(  "8     //
//     888    "    888   888   888    888    888  888   888  888   888  `"Y88b.      //
//     888       o 888   888   888    888 .  888  888   888  888   888  o.  )88b     //
//    o888ooooood8 `Y8bod88P" o888o   "888" o888o `Y8bod8P' o888o o888o 8""888P'     //
//                                                                                   //
//                                                                                   //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract ARSE is ERC1155Creator {
    constructor() ERC1155Creator("Arsonic Editions", "ARSE") {}
}
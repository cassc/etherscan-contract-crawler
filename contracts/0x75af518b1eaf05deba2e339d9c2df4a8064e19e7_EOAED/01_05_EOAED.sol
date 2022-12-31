// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Emphasis or Antithesis ED
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                                                                                                                                           //
//                                                                                                                                           //
//             oooo                .   oooo                         oooooooooooo   .oooooo.         .o.       oooooooooooo oooooooooo.       //
//             `888              .o8   `888                         `888'     `8  d8P'  `Y8b       .888.      `888'     `8 `888'   `Y8b      //
//     .oooo.o  888   .ooooo.  .o888oo  888 .oo.   oooo    ooo       888         888      888     .8"888.      888          888      888     //
//    d88(  "8  888  d88' `88b   888    888P"Y88b   `88.  .8'        888oooo8    888      888    .8' `888.     888oooo8     888      888     //
//    `"Y88b.   888  888   888   888    888   888    `88..8'         888    "    888      888   .88ooo8888.    888    "     888      888     //
//    o.  )88b  888  888   888   888 .  888   888     `888'          888       o `88b    d88'  .8'     `888.   888       o  888     d88'     //
//    8""888P' o888o `Y8bod8P'   "888" o888o o888o     .8'          o888ooooood8  `Y8bood8P'  o88o     o8888o o888ooooood8 o888bood8P'       //
//                                                 .o..P'                                                                                    //
//                                                 `Y8P'                                                                                     //
//                                                                                                                                           //
//                                                                                                                                           //
//                                                                                                                                           //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EOAED is ERC1155Creator {
    constructor() ERC1155Creator("Emphasis or Antithesis ED", "EOAED") {}
}
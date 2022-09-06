// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Inner Beasts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                           //
//                                                                                                                                                           //
//    ooooo ooooo      ooo ooooo      ooo oooooooooooo ooooooooo.        oooooooooo.  oooooooooooo       .o.        .oooooo..o ooooooooooooo  .oooooo..o     //
//    `888' `888b.     `8' `888b.     `8' `888'     `8 `888   `Y88.      `888'   `Y8b `888'     `8      .888.      d8P'    `Y8 8'   888   `8 d8P'    `Y8     //
//     888   8 `88b.    8   8 `88b.    8   888          888   .d88'       888     888  888             .8"888.     Y88bo.           888      Y88bo.          //
//     888   8   `88b.  8   8   `88b.  8   888oooo8     888ooo88P'        888oooo888'  888oooo8       .8' `888.     `"Y8888o.       888       `"Y8888o.      //
//     888   8     `88b.8   8     `88b.8   888    "     888`88b.          888    `88b  888    "      .88ooo8888.        `"Y88b      888           `"Y88b     //
//     888   8       `888   8       `888   888       o  888  `88b.        888    .88P  888       o  .8'     `888.  oo     .d8P      888      oo     .d8P     //
//    o888o o8o        `8  o8o        `8  o888ooooood8 o888o  o888o      o888bood8P'  o888ooooood8 o88o     o8888o 8""88888P'      o888o     8""88888P'      //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//     .o8                                                      .oooooo..o                                                 .oo.                     o8o      //
//    "888                                                     d8P'    `Y8                                               .88' `8.                   `"'      //
//     888oooo.  oooo    ooo       .oooooooo ooo. .oo.  .oo.   Y88bo.      oo.ooooo.   .oooo.    .ooooo.   .ooooo.       88.  .8'         .oooo.   oooo      //
//     d88' `88b  `88.  .8'       888' `88b  `888P"Y88bP"Y88b   `"Y8888o.   888' `88b `P  )88b  d88' `"Y8 d88' `88b      `88.8P          `P  )88b  `888      //
//     888   888   `88..8'        888   888   888   888   888       `"Y88b  888   888  .oP"888  888       888ooo888       d888[.8'        .oP"888   888      //
//     888   888    `888'         `88bod8P'   888   888   888  oo     .d8P  888   888 d8(  888  888   .o8 888    .o      88' `88.        d8(  888   888      //
//     `Y8bod8P'     .8'          `8oooooo.  o888o o888o o888o 8""88888P'   888bod8P' `Y888""8o `Y8bod8P' `Y8bod8P'      `bodP'`88.      `Y888""8o o888o     //
//               .o..P'           d"     YD                                 888                                                                              //
//               `Y8P'            "Y88888P'                                o888o                                                                             //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BEAST is ERC721Creator {
    constructor() ERC721Creator("Inner Beasts", "BEAST") {}
}
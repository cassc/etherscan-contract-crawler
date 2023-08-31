// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by Nicolas Davis
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                  //
//                                                                                                                                  //
//    ooooo      ooo  o8o                      oooo                          oooooooooo.                          o8o               //
//    `888b.     `8'  `"'                      `888                          `888'   `Y8b                         `"'               //
//     8 `88b.    8  oooo   .ooooo.   .ooooo.   888   .oooo.    .oooo.o       888      888  .oooo.   oooo    ooo oooo   .oooo.o     //
//     8   `88b.  8  `888  d88' `"Y8 d88' `88b  888  `P  )88b  d88(  "8       888      888 `P  )88b   `88.  .8'  `888  d88(  "8     //
//     8     `88b.8   888  888       888   888  888   .oP"888  `"Y88b.        888      888  .oP"888    `88..8'    888  `"Y88b.      //
//     8       `888   888  888   .o8 888   888  888  d8(  888  o.  )88b       888     d88' d8(  888     `888'     888  o.  )88b     //
//    o8o        `8  o888o `Y8bod8P' `Y8bod8P' o888o `Y888""8o 8""888P'      o888bood8P'   `Y888""8o     `8'     o888o 8""888P'     //
//                                                                                                                                  //
//                                                                                                                                  //
//                                                                                                                                  //
//                                                                                                                                  //
//                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NICD is ERC1155Creator {
    constructor() ERC1155Creator("Editions by Nicolas Davis", "NICD") {}
}
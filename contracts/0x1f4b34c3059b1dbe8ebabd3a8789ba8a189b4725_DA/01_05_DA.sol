// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Diakova Alisa
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                      //
//                                                                                                                                      //
//    oooooooooo.    o8o            oooo                                                   .o.       oooo   o8o                         //
//    `888'   `Y8b   `"'            `888                                                  .888.      `888   `"'                         //
//     888      888 oooo   .oooo.    888  oooo   .ooooo.  oooo    ooo  .oooo.            .8"888.      888  oooo   .oooo.o  .oooo.       //
//     888      888 `888  `P  )88b   888 .8P'   d88' `88b  `88.  .8'  `P  )88b          .8' `888.     888  `888  d88(  "8 `P  )88b      //
//     888      888  888   .oP"888   888888.    888   888   `88..8'    .oP"888         .88ooo8888.    888   888  `"Y88b.   .oP"888      //
//     888     d88'  888  d8(  888   888 `88b.  888   888    `888'    d8(  888        .8'     `888.   888   888  o.  )88b d8(  888      //
//    o888bood8P'   o888o `Y888""8o o888o o888o `Y8bod8P'     `8'     `Y888""8o      o88o     o8888o o888o o888o 8""888P' `Y888""8o     //
//                                                                                                                                      //
//                                                                                                                                      //
//    Creator Diakova Alisa                                                                                                             //
//                                                                                                                                      //
//                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DA is ERC721Creator {
    constructor() ERC721Creator("Diakova Alisa", "DA") {}
}
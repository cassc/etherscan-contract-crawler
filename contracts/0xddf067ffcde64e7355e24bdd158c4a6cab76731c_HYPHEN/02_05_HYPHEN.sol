// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HyphenStudio's world
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                            //
//                                                                                                                                            //
//    ooooo   ooooo                        oooo                                           .                     .o8   o8o                     //
//    `888'   `888'                        `888                                         .o8                    "888   `"'                     //
//     888     888  oooo    ooo oo.ooooo.   888 .oo.    .ooooo.  ooo. .oo.    .oooo.o .o888oo oooo  oooo   .oooo888  oooo   .ooooo.           //
//     888ooooo888   `88.  .8'   888' `88b  888P"Y88b  d88' `88b `888P"Y88b  d88(  "8   888   `888  `888  d88' `888  `888  d88' `88b          //
//     888     888    `88..8'    888   888  888   888  888ooo888  888   888  `"Y88b.    888    888   888  888   888   888  888   888          //
//     888     888     `888'     888   888  888   888  888    .o  888   888  o.  )88b   888 .  888   888  888   888   888  888   888          //
//    o888o   o888o     .8'      888bod8P' o888o o888o `Y8bod8P' o888o o888o 8""888P'   "888"  `V88V"V8P' `Y8bod88P" o888o `Y8bod8P'          //
//                  .o..P'       888                                                                                                          //
//                  `Y8P'       o888o                                                                                                         //
//                                                                                                                                            //
//                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HYPHEN is ERC721Creator {
    constructor() ERC721Creator("HyphenStudio's world", "HYPHEN") {}
}
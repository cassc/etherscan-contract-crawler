// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: jhan
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//                                                                                                                          //
//     .o88o.                           .o8   .o8                           oooo                            oooo  oooo      //
//     888 `"                          "888  "888                           `888                            `888  `888      //
//    o888oo   .ooooo.   .ooooo.   .oooo888   888oooo.   .oooo.    .ooooo.   888  oooo   .ooooo.   .ooooo.   888   888      //
//     888    d88' `88b d88' `88b d88' `888   d88' `88b `P  )88b  d88' `"Y8  888 .8P'   d88' `"Y8 d88' `88b  888   888      //
//     888    888ooo888 888ooo888 888   888   888   888  .oP"888  888        888888.    888       888ooo888  888   888      //
//     888    888    .o 888    .o 888   888   888   888 d8(  888  888   .o8  888 `88b.  888   .o8 888    .o  888   888      //
//    o888o   `Y8bod8P' `Y8bod8P' `Y8bod88P"  `Y8bod8P' `Y888""8o `Y8bod8P' o888o o888o `Y8bod8P' `Y8bod8P' o888o o888o     //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract jhn is ERC721Creator {
    constructor() ERC721Creator("jhan", "jhn") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lost Gem
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//                                                                                               //
//    ooooo                               .          .oooooo.                                    //
//    `888'                             .o8         d8P'  `Y8b                                   //
//     888          .ooooo.   .oooo.o .o888oo      888            .ooooo.  ooo. .oo.  .oo.       //
//     888         d88' `88b d88(  "8   888        888           d88' `88b `888P"Y88bP"Y88b      //
//     888         888   888 `"Y88b.    888        888     ooooo 888ooo888  888   888   888      //
//     888       o 888   888 o.  )88b   888 .      `88.    .88'  888    .o  888   888   888      //
//    o888ooooood8 `Y8bod8P' 8""888P'   "888"       `Y8bood8P'   `Y8bod8P' o888o o888o o888o     //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


contract LG is ERC721Creator {
    constructor() ERC721Creator("Lost Gem", "LG") {}
}
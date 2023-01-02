// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fuzzle Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//     .o88o.                                   oooo                //
//     888 `"                                   `888                //
//    o888oo  oooo  oooo    oooooooo   oooooooo  888   .ooooo.      //
//     888    `888  `888   d'""7d8P   d'""7d8P   888  d88' `88b     //
//     888     888   888     .d8P'      .d8P'    888  888ooo888     //
//     888     888   888   .d8P'  .P  .d8P'  .P  888  888    .o     //
//    o888o    `V88V"V8P' d8888888P  d8888888P  o888o `Y8bod8P'     //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract FUZZ23 is ERC721Creator {
    constructor() ERC721Creator("Fuzzle Editions", "FUZZ23") {}
}
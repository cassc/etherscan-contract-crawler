// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Abandoned Refuse
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//    ooooooooo.              .o88o.                                              //
//    `888   `Y88.            888 `"                                              //
//     888   .d88'  .ooooo.  o888oo  oooo  oooo   .oooo.o  .ooooo.                //
//     888ooo88P'  d88' `88b  888    `888  `888  d88(  "8 d88' `88b               //
//     888`88b.    888ooo888  888     888   888  `"Y88b.  888ooo888               //
//     888  `88b.  888    .o  888     888   888  o.  )88b 888    .o               //
//    o888o  o888o `Y8bod8P' o888o    `V88V"V8P' 8""888P' `Y8bod8P'               //
//                                                                  ooooooooo.    //
//    ooooooooo.              .o88o.                                              //
//    `888   `Y88.            888 `"                                              //
//     888   .d88'  .ooooo.  o888oo  oooo  oooo   .oooo.o  .ooooo.                //
//     888ooo88P'  d88' `88b  888    `888  `888  d88(  "8 d88' `88b               //
//     888`88b.    888ooo888  888     888   888  `"Y88b.  888ooo888               //
//     888  `88b.  888    .o  888     888   888  o.  )88b 888    .o               //
//    o888o  o888o `Y8bod8P' o888o    `V88V"V8P' 8""888P' `Y8bod8P'               //
//                                                                  ooooooooo.    //
//    ooooooooo.              .o88o.                                              //
//    `888   `Y88.            888 `"                                              //
//     888   .d88'  .ooooo.  o888oo  oooo  oooo   .oooo.o  .ooooo.                //
//     888ooo88P'  d88' `88b  888    `888  `888  d88(  "8 d88' `88b               //
//     888`88b.    888ooo888  888     888   888  `"Y88b.  888ooo888               //
//     888  `88b.  888    .o  888     888   888  o.  )88b 888    .o               //
//    o888o  o888o `Y8bod8P' o888o    `V88V"V8P' 8""888P' `Y8bod8P'               //
//                                                                  ooooooooo.    //
//    ooooooooo.              .o88o.                                              //
//    `888   `Y88.            888 `"                                              //
//     888   .d88'  .ooooo.  o888oo  oooo  oooo   .oooo.o  .ooooo.                //
//     888ooo88P'  d88' `88b  888    `888  `888  d88(  "8 d88' `88b               //
//     888`88b.    888ooo888  888     888   888  `"Y88b.  888ooo888               //
//     888  `88b.  888    .o  888     888   888  o.  )88b 888    .o               //
//    o888o  o888o `Y8bod8P' o888o    `V88V"V8P' 8""888P' `Y8bod8P'               //
//                                                                  ooooooooo.    //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract refuse is ERC721Creator {
    constructor() ERC721Creator("Abandoned Refuse", "refuse") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TheArticist's Figurative Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//    ooooooooooooo oooo                        .o.                    .    o8o             o8o               .       //
//    8'   888   `8 `888                       .888.                 .o8    `"'             `"'             .o8       //
//         888       888 .oo.    .ooooo.      .8"888.     oooo d8b .o888oo oooo   .ooooo.  oooo   .oooo.o .o888oo     //
//         888       888P"Y88b  d88' `88b    .8' `888.    `888""8P   888   `888  d88' `"Y8 `888  d88(  "8   888       //
//         888       888   888  888ooo888   .88ooo8888.    888       888    888  888        888  `"Y88b.    888       //
//         888       888   888  888    .o  .8'     `888.   888       888 .  888  888   .o8  888  o.  )88b   888 .     //
//        o888o     o888o o888o `Y8bod8P' o88o     o8888o d888b      "888" o888o `Y8bod8P' o888o 8""888P'   "888"     //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RTCST1 is ERC721Creator {
    constructor() ERC721Creator("TheArticist's Figurative Art", "RTCST1") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hope for Iran
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                           //
//                                                                                                                           //
//      .oooooo.    .o8                                                                                                      //
//     d8P'  `Y8b  "888                                                                                                      //
//    888      888  888oooo.   .oooo.o  .ooooo.  oooo  oooo  oooo d8b  .oooo.                                                //
//    888      888  d88' `88b d88(  "8 d88' `"Y8 `888  `888  `888""8P `P  )88b                                               //
//    888      888  888   888 `"Y88b.  888        888   888   888      .oP"888                                               //
//    `88b    d88'  888   888 o.  )88b 888   .o8  888   888   888     d8(  888                                               //
//     `Y8bood8P'   `Y8bod8P' 8""888P' `Y8bod8P'  `V88V"V8P' d888b    `Y888""8o                                              //
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
//    ooooo   ooooo                                    .o88o.                       ooooo                                    //
//    `888'   `888'                                    888 `"                       `888'                                    //
//     888     888   .ooooo.  oo.ooooo.   .ooooo.     o888oo   .ooooo.  oooo d8b     888  oooo d8b  .oooo.   ooo. .oo.       //
//     888ooooo888  d88' `88b  888' `88b d88' `88b     888    d88' `88b `888""8P     888  `888""8P `P  )88b  `888P"Y88b      //
//     888     888  888   888  888   888 888ooo888     888    888   888  888         888   888      .oP"888   888   888      //
//     888     888  888   888  888   888 888    .o     888    888   888  888         888   888     d8(  888   888   888      //
//    o888o   o888o `Y8bod8P'  888bod8P' `Y8bod8P'    o888o   `Y8bod8P' d888b       o888o d888b    `Y888""8o o888o o888o     //
//                             888                                                                                           //
//                            o888o                                                                                          //
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HOPE is ERC721Creator {
    constructor() ERC721Creator("Hope for Iran", "HOPE") {}
}
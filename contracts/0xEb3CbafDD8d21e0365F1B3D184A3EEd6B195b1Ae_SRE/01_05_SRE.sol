// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sergei Ramos Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                           //
//                                                                                                                                                                                           //
//    .oooooo..o                                          o8o       ooooooooo.                                                                                                               //
//    d8P'    `Y8                                          `"'       `888   `Y88.                                                                                                            //
//    Y88bo.       .ooooo.  oooo d8b  .oooooooo  .ooooo.  oooo        888   .d88'  .oooo.   ooo. .oo.  .oo.    .ooooo.   .oooo.o                                                             //
//     `"Y8888o.  d88' `88b `888""8P 888' `88b  d88' `88b `888        888ooo88P'  `P  )88b  `888P"Y88bP"Y88b  d88' `88b d88(  "8                                                             //
//         `"Y88b 888ooo888  888     888   888  888ooo888  888        888`88b.     .oP"888   888   888   888  888   888 `"Y88b.                                                              //
//    oo     .d8P 888    .o  888     `88bod8P'  888    .o  888        888  `88b.  d8(  888   888   888   888  888   888 o.  )88b                                                             //
//    8""88888P'  `Y8bod8P' d888b    `8oooooo.  `Y8bod8P' o888o      o888o  o888o `Y888""8o o888o o888o o888o `Y8bod8P' 8""888P'                                                             //
//                                   d"     YD                                                                                                                                               //
//                                   "Y88888P'                                                                                                                                               //
//                                                                                                                                                                                           //
//                                                                                                                                                                                           //
//                                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SRE is ERC721Creator {
    constructor() ERC721Creator("Sergei Ramos Editions", "SRE") {}
}
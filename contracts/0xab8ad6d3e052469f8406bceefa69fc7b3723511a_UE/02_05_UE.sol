// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ucneto Eoni
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//    ooooo     ooo                                     .                      //
//    `888'     `8'                                   .o8                      //
//     888       8   .ooooo.  ooo. .oo.    .ooooo.  .o888oo  .ooooo.           //
//     888       8  d88' `"Y8 `888P"Y88b  d88' `88b   888   d88' `88b          //
//     888       8  888        888   888  888ooo888   888   888   888          //
//     `88.    .8'  888   .o8  888   888  888    .o   888 . 888   888          //
//       `YbodP'    `Y8bod8P' o888o o888o `Y8bod8P'   "888" `Y8bod8P'          //
//                                                                             //
//                                                                             //
//                                                                             //
//              oooooooooooo                        o8o                        //
//              `888'     `8                        `"'                        //
//               888          .ooooo.  ooo. .oo.   oooo                        //
//               888oooo8    d88' `88b `888P"Y88b  `888                        //
//               888    "    888   888  888   888   888                        //
//               888       o 888   888  888   888   888                        //
//              o888ooooood8 `Y8bod8P' o888o o888o o888o                       //
//                                                                             //
//                                                                             //
//                  by Ilya Kolesnikov & Inoe Otencu                           //
//                                                                             //
//                                                                             //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract UE is ERC721Creator {
    constructor() ERC721Creator("Ucneto Eoni", "UE") {}
}
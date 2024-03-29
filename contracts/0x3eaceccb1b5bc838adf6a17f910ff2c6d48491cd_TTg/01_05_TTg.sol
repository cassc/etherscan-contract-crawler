// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 10 To Treasure (8)
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//     ________  ________  _______   _______   ________   ___  ___  ________  ___  ________         //
//    |\   ____\|\   __  \|\  ___ \ |\  ___ \ |\   ___  \|\  \|\  \|\   __  \|\  \|\   __  \        //
//    \ \  \___|\ \  \|\  \ \   __/|\ \   __/|\ \  \\ \  \ \  \\\  \ \  \|\  \ \  \ \  \|\  \       //
//     \ \  \  __\ \   _  _\ \  \_|/_\ \  \_|/_\ \  \\ \  \ \   __  \ \   __  \ \  \ \   _  _\      //
//      \ \  \|\  \ \  \\  \\ \  \_|\ \ \  \_|\ \ \  \\ \  \ \  \ \  \ \  \ \  \ \  \ \  \\  \|     //
//       \ \_______\ \__\\ _\\ \_______\ \_______\ \__\\ \__\ \__\ \__\ \__\ \__\ \__\ \__\\ _\     //
//        \|_______|\|__|\|__|\|_______|\|_______|\|__| \|__|\|__|\|__|\|__|\|__|\|__|\|__|\|__|    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract TTg is ERC1155Creator {
    constructor() ERC1155Creator("10 To Treasure (8)", "TTg") {}
}
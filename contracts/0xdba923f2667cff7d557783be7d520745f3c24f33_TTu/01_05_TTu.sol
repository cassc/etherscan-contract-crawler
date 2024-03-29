// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 10 To Treasure (3)
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//     ________  _______   ________  ________   ________  ________  ________  _______   ________  ________  ___  ________         //
//    |\   __  \|\  ___ \ |\   __  \|\   ___  \|\   ____\|\   ___ \|\   __  \|\  ___ \ |\   ____\|\   __  \|\  \|\_____  \        //
//    \ \  \|\ /\ \   __/|\ \  \|\  \ \  \\ \  \ \  \___|\ \  \_|\ \ \  \|\  \ \   __/|\ \  \___|\ \  \|\ /\ \  \\|___/  /|       //
//     \ \   __  \ \  \_|/_\ \   __  \ \  \\ \  \ \_____  \ \  \ \\ \ \  \\\  \ \  \_|/_\ \_____  \ \   __  \ \  \   /  / /       //
//      \ \  \|\  \ \  \_|\ \ \  \ \  \ \  \\ \  \|____|\  \ \  \_\\ \ \  \\\  \ \  \_|\ \|____|\  \ \  \|\  \ \  \ /  /_/__      //
//       \ \_______\ \_______\ \__\ \__\ \__\\ \__\____\_\  \ \_______\ \_______\ \_______\____\_\  \ \_______\ \__\\________\    //
//        \|_______|\|_______|\|__|\|__|\|__| \|__|\_________\|_______|\|_______|\|_______|\_________\|_______|\|__|\|_______|    //
//                                                \|_________|                            \|_________|                            //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TTu is ERC1155Creator {
    constructor() ERC1155Creator("10 To Treasure (3)", "TTu") {}
}
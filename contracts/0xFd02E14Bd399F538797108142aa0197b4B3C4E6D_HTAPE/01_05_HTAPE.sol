// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HTML APES
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//     ___  ___  _________  _____ ______   ___               ________  ________  _______   ________          //
//    |\  \|\  \|\___   ___\\   _ \  _   \|\  \             |\   __  \|\   __  \|\  ___ \ |\   ____\         //
//    \ \  \\\  \|___ \  \_\ \  \\\__\ \  \ \  \            \ \  \|\  \ \  \|\  \ \   __/|\ \  \___|_        //
//     \ \   __  \   \ \  \ \ \  \\|__| \  \ \  \            \ \   __  \ \   ____\ \  \_|/_\ \_____  \       //
//      \ \  \ \  \   \ \  \ \ \  \    \ \  \ \  \____        \ \  \ \  \ \  \___|\ \  \_|\ \|____|\  \      //
//       \ \__\ \__\   \ \__\ \ \__\    \ \__\ \_______\       \ \__\ \__\ \__\    \ \_______\____\_\  \     //
//        \|__|\|__|    \|__|  \|__|     \|__|\|_______|        \|__|\|__|\|__|     \|_______|\_________\    //
//                                                                                           \|_________|    //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HTAPE is ERC1155Creator {
    constructor() ERC1155Creator("HTML APES", "HTAPE") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 3D Animated Picture
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//     ________  ________          ________  ________   ___  _____ ______   ________  _________  _______   ________          ________  ___  ________ _________  ___  ___  ________  _______          //
//    |\_____  \|\   ___ \        |\   __  \|\   ___  \|\  \|\   _ \  _   \|\   __  \|\___   ___\\  ___ \ |\   ___ \        |\   __  \|\  \|\   ____\\___   ___\\  \|\  \|\   __  \|\  ___ \         //
//    \|____|\ /\ \  \_|\ \       \ \  \|\  \ \  \\ \  \ \  \ \  \\\__\ \  \ \  \|\  \|___ \  \_\ \   __/|\ \  \_|\ \       \ \  \|\  \ \  \ \  \___\|___ \  \_\ \  \\\  \ \  \|\  \ \   __/|        //
//          \|\  \ \  \ \\ \       \ \   __  \ \  \\ \  \ \  \ \  \\|__| \  \ \   __  \   \ \  \ \ \  \_|/_\ \  \ \\ \       \ \   ____\ \  \ \  \       \ \  \ \ \  \\\  \ \   _  _\ \  \_|/__      //
//         __\_\  \ \  \_\\ \       \ \  \ \  \ \  \\ \  \ \  \ \  \    \ \  \ \  \ \  \   \ \  \ \ \  \_|\ \ \  \_\\ \       \ \  \___|\ \  \ \  \____   \ \  \ \ \  \\\  \ \  \\  \\ \  \_|\ \     //
//        |\_______\ \_______\       \ \__\ \__\ \__\\ \__\ \__\ \__\    \ \__\ \__\ \__\   \ \__\ \ \_______\ \_______\       \ \__\    \ \__\ \_______\  \ \__\ \ \_______\ \__\\ _\\ \_______\    //
//        \|_______|\|_______|        \|__|\|__|\|__| \|__|\|__|\|__|     \|__|\|__|\|__|    \|__|  \|_______|\|_______|        \|__|     \|__|\|_______|   \|__|  \|_______|\|__|\|__|\|_______|    //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AP3D is ERC721Creator {
    constructor() ERC721Creator("3D Animated Picture", "AP3D") {}
}
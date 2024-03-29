// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Home
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//                                                                   //
//     ___  ___  ________  _____ ______   _______                    //
//    |\  \|\  \|\   __  \|\   _ \  _   \|\  ___ \                   //
//    \ \  \\\  \ \  \|\  \ \  \\\__\ \  \ \   __/|                  //
//     \ \   __  \ \  \\\  \ \  \\|__| \  \ \  \_|/__                //
//      \ \  \ \  \ \  \\\  \ \  \    \ \  \ \  \_|\ \               //
//       \ \__\ \__\ \_______\ \__\    \ \__\ \_______\              //
//        \|__|\|__|\|_______|\|__|     \|__|\|_______|              //
//                                                                   //
//                                                                   //
//                                                                   //
//     ________      ___    ___                                      //
//    |\   __  \    |\  \  /  /|                                     //
//    \ \  \|\ /_   \ \  \/  / /                                     //
//     \ \   __  \   \ \    / /                                      //
//      \ \  \|\  \   \/  /  /                                       //
//       \ \_______\__/  / /                                         //
//        \|_______|\___/ /                                          //
//                 \|___|/                                           //
//                                                                   //
//                                                                   //
//     ________  ___       ________  ___       __   ________         //
//    |\   ___ \|\  \     |\   __  \|\  \     |\  \|\   __  \        //
//    \ \  \_|\ \ \  \    \ \  \|\  \ \  \    \ \  \ \  \|\  \       //
//     \ \  \ \\ \ \  \    \ \   __  \ \  \  __\ \  \ \   _  _\      //
//      \ \  \_\\ \ \  \____\ \  \ \  \ \  \|\__\_\  \ \  \\  \|     //
//       \ \_______\ \_______\ \__\ \__\ \____________\ \__\\ _\     //
//        \|_______|\|_______|\|__|\|__|\|____________|\|__|\|__|    //
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract HME is ERC721Creator {
    constructor() ERC721Creator("Home", "HME") {}
}
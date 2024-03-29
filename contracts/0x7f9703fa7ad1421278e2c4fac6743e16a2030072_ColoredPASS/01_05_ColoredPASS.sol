// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Colored [LC PASS]
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//     ________  ________  ___       ________  ________  _______   ________          ________  ________  ________   ________          //
//    |\   ____\|\   __  \|\  \     |\   __  \|\   __  \|\  ___ \ |\   ___ \        |\   __  \|\   __  \|\   ____\ |\   ____\         //
//    \ \  \___|\ \  \|\  \ \  \    \ \  \|\  \ \  \|\  \ \   __/|\ \  \_|\ \       \ \  \|\  \ \  \|\  \ \  \___|_\ \  \___|_        //
//     \ \  \    \ \  \\\  \ \  \    \ \  \\\  \ \   _  _\ \  \_|/_\ \  \ \\ \       \ \   ____\ \   __  \ \_____  \\ \_____  \       //
//      \ \  \____\ \  \\\  \ \  \____\ \  \\\  \ \  \\  \\ \  \_|\ \ \  \_\\ \       \ \  \___|\ \  \ \  \|____|\  \\|____|\  \      //
//       \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \_______\ \_______\       \ \__\    \ \__\ \__\____\_\  \ ____\_\  \     //
//        \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|_______|\|_______|        \|__|     \|__|\|__|\_________\\_________\    //
//                                                                                                         \|_________\|_________|    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ColoredPASS is ERC721Creator {
    constructor() ERC721Creator("Colored [LC PASS]", "ColoredPASS") {}
}
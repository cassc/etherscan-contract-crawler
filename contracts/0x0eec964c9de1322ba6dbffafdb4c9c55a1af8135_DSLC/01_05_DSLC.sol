// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DESOLC
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//     ________   _______   ________  ________         //
//    |\   ___  \|\  ___ \ |\   __  \|\   __  \        //
//    \ \  \\ \  \ \   __/|\ \  \|\  \ \  \|\  \       //
//     \ \  \\ \  \ \  \_|/_\ \   ____\ \  \\\  \      //
//      \ \  \\ \  \ \  \_|\ \ \  \___|\ \  \\\  \     //
//       \ \__\\ \__\ \_______\ \__\    \ \_______\    //
//        \|__| \|__|\|_______|\|__|     \|_______|    //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract DSLC is ERC721Creator {
    constructor() ERC721Creator("DESOLC", "DSLC") {}
}
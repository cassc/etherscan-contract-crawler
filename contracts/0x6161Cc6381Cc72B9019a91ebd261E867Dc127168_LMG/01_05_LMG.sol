// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LMG Racing Club
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//     ___       _____ ______   ________         //
//    |\  \     |\   _ \  _   \|\   ____\        //
//    \ \  \    \ \  \\\__\ \  \ \  \___|        //
//     \ \  \    \ \  \\|__| \  \ \  \  ___      //
//      \ \  \____\ \  \    \ \  \ \  \|\  \     //
//       \ \_______\ \__\    \ \__\ \_______\    //
//        \|_______|\|__|     \|__|\|_______|    //
//                                               //
//                                               //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract LMG is ERC721Creator {
    constructor() ERC721Creator("LMG Racing Club", "LMG") {}
}
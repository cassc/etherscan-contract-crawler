// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Grape Necklace
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//            ___         ___      //
//      .'|=|_.'    .'| |   |      //
//    .'  |___    .'  |\|   |      //
//    |   |`._|=. |   | |   |      //
//    `.  |  __|| |   | |  .'      //
//      `.|=|_.'' |___| |.'        //
//                                 //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract GN is ERC721Creator {
    constructor() ERC721Creator("Grape Necklace", "GN") {}
}
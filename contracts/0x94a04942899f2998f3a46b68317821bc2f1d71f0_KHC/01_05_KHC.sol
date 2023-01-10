// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KURT HUSTLE COLLECTIVE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//     ___  __     ___  ___   ________         //
//    |\  \|\  \  |\  \|\  \ |\   ____\        //
//    \ \  \/  /|_\ \  \\\  \\ \  \___|        //
//     \ \   ___  \\ \   __  \\ \  \           //
//      \ \  \\ \  \\ \  \ \  \\ \  \____      //
//       \ \__\\ \__\\ \__\ \__\\ \_______\    //
//        \|__| \|__| \|__|\|__| \|_______|    //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract KHC is ERC721Creator {
    constructor() ERC721Creator("KURT HUSTLE COLLECTIVE", "KHC") {}
}
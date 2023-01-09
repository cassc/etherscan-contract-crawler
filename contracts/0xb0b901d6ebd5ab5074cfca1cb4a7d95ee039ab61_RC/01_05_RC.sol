// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rare Collage
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//     ________  ________         //
//    |\   __  \|\   ____\        //
//    \ \  \|\  \ \  \___|        //
//     \ \   _  _\ \  \           //
//      \ \  \\  \\ \  \____      //
//       \ \__\\ _\\ \_______\    //
//        \|__|\|__|\|_______|    //
//                                //
//                                //
//                                //
//                                //
//                                //
////////////////////////////////////


contract RC is ERC721Creator {
    constructor() ERC721Creator("Rare Collage", "RC") {}
}
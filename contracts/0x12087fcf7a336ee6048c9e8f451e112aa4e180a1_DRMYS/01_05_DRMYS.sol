// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dreamy Seasons
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//         _                                   //
//        | |                                  //
//      __| | ____ _____ _____ ____  _   _     //
//     / _  |/ ___) ___ (____ |    \| | | |    //
//    ( (_| | |   | ____/ ___ | | | | |_| |    //
//     \____|_|   |_____)_____|_|_|_|\__  |    //
//                           seasons(____/     //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract DRMYS is ERC1155Creator {
    constructor() ERC1155Creator("Dreamy Seasons", "DRMYS") {}
}
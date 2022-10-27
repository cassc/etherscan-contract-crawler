// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MG_PFPs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//     _____ ______   ________         //
//    |\   _ \  _   \|\   ____\        //
//    \ \  \\\__\ \  \ \  \___|        //
//     \ \  \\|__| \  \ \  \  ___      //
//      \ \  \    \ \  \ \  \|\  \     //
//       \ \__\    \ \__\ \_______\    //
//        \|__|     \|__|\|_______|    //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract MGPFP is ERC721Creator {
    constructor() ERC721Creator("MG_PFPs", "MGPFP") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Promo Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//     ________  _____ ______          //
//    |\   ____\|\   _ \  _   \        //
//    \ \  \___|\ \  \\\__\ \  \       //
//     \ \  \  __\ \  \\|__| \  \      //
//      \ \  \|\  \ \  \    \ \  \     //
//       \ \_______\ \__\    \ \__\    //
//        \|_______|\|__|     \|__|    //
//                                     //
//                                     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract PRED is ERC1155Creator {
    constructor() ERC1155Creator("Promo Editions", "PRED") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Curly Goddess
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//    ___       ___                          //
//     |  |__| |__                           //
//     |  |  | |___                          //
//                                           //
//     __        __                          //
//    /  ` |  | |__) |    \ /                //
//    \__, \__/ |  \ |___  |                 //
//                                           //
//     __   __   __   __   ___  __   __      //
//    / _` /  \ |  \ |  \ |__  /__` /__`     //
//    \__> \__/ |__/ |__/ |___ .__/ .__/     //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract CurlyGDSS is ERC721Creator {
    constructor() ERC721Creator("The Curly Goddess", "CurlyGDSS") {}
}
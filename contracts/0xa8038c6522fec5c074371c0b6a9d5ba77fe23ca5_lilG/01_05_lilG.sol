// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: grey iterated
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//    |    | |                               //
//    |___ | |___                            //
//                                           //
//     __   __   ___                         //
//    / _` |__) |__  \ /                     //
//    \__> |  \ |___  |                      //
//                                           //
//              __                           //
//    |  | |  |  /                           //
//    |/\| \__/ /_                           //
//                                           //
//          ___  __   ___            __      //
//    |__| |__  |__) |__           .|  \     //
//    |  | |___ |  \ |___ ...      .|__/     //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract lilG is ERC721Creator {
    constructor() ERC721Creator("grey iterated", "lilG") {}
}
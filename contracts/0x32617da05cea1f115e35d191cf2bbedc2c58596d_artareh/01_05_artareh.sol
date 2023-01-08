// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: writing is art
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//       ______             __                  __      //
//      / ____ \____ ______/ /_____ _________  / /_     //
//     / / __ `/ __ `/ ___/ __/ __ `/ ___/ _ \/ __ \    //
//    / / /_/ / /_/ / /  / /_/ /_/ / /  /  __/ / / /    //
//    \ \__,_/\__,_/_/   \__/\__,_/_/   \___/_/ /_/     //
//     \____/                                           //
//                                                      //
//    //                                                //
//    @atareh                                           //
//    @artareh                                          //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract artareh is ERC1155Creator {
    constructor() ERC1155Creator("writing is art", "artareh") {}
}
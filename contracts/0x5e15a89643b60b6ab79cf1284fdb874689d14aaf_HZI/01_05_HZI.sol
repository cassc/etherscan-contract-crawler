// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hyper-Zoom
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//      ^    ^    ^    ^    ^    ^    ^                                      //
//     /Z\  /O\  /O\  /M\  /-\  /I\  /N\                                     //
//    <___><___><___><___><___><___><___>                                    //
//                                                                           //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract HZI is ERC1155Creator {
    constructor() ERC1155Creator("Hyper-Zoom", "HZI") {}
}
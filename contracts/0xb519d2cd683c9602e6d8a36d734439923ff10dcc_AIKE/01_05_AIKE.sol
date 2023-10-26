// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AI KALEIDOSCOPE EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//    _    _ _____ ______  _______      ______   ______  _____   _____  _______     //
//      \  /    |   |_____] |______      |     \ |_____/ |     | |_____] |______    //
//       \/   __|__ |_____] |______      |_____/ |    \_ |_____| |       ______|    //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract AIKE is ERC1155Creator {
    constructor() ERC1155Creator("AI KALEIDOSCOPE EDITIONS", "AIKE") {}
}
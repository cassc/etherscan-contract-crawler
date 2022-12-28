// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Open Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//      _ \                    ____|     |_) |  _)                 //
//     |   | __ \   _ \ __ \   __|    _` | | __| |  _ \  __ \      //
//     |   | |   |  __/ |   |  |     (   | | |   | (   | |   |     //
//    \___/  .__/ \___|_|  _| _____|\__,_|_|\__|_|\___/ _|  _|     //
//          _|                                                     //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract DBOPEN is ERC1155Creator {
    constructor() ERC1155Creator("Open Edition", "DBOPEN") {}
}
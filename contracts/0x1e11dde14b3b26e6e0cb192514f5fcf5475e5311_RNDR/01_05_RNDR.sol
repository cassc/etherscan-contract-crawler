// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Render AI
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                   _            _____ _____     //
//     ___ ___ ___ _| |___ ___   |  _  |     |    //
//    |  _| -_|   | . | -_|  _|  |     |-   -|    //
//    |_| |___|_|_|___|___|_|    |__|__|_____|    //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract RNDR is ERC1155Creator {
    constructor() ERC1155Creator("Render AI", "RNDR") {}
}
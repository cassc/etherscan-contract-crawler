// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ready to Ride
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//                                                                             _____     //
//     _____ _____ _____ ____  __ __    _____ _____    _____ _____ ____  _____|___  |    //
//    | __  |   __|  _  |    \|  |  |  |_   _|     |  | __  |     |    \|   __| |  _|    //
//    |    -|   __|     |  |  |_   _|    | | |  |  |  |    -|-   -|  |  |   __| |_|      //
//    |__|__|_____|__|__|____/  |_|      |_| |_____|  |__|__|_____|____/|_____| |_|      //
//                                                                                       //
//                                                                                       //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract RTR is ERC1155Creator {
    constructor() ERC1155Creator("Ready to Ride", "RTR") {}
}
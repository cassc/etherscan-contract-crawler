// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: #0MRobo
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//     ___ _____ _____ _____ _____ _____     //
//    |   |     | __  |     | __  |     |    //
//    | | | | | |    -|  |  | __ -|  |  |    //
//    |___|_|_|_|__|__|_____|_____|_____|    //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract ROBO is ERC1155Creator {
    constructor() ERC1155Creator("#0MRobo", "ROBO") {}
}
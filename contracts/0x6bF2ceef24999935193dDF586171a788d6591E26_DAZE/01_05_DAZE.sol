// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DAZE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//                                   //
//     ____  _____ _____ _____       //
//    |    \|  _  |__   |   __|      //
//    |  |  |     |   __|   __|      //
//    |____/|__|__|_____|_____|      //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract DAZE is ERC721Creator {
    constructor() ERC721Creator("DAZE", "DAZE") {}
}
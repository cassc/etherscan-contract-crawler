// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ODES
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//     _____ ____  _____ _____     //
//    |     |    \|   __|   __|    //
//    |  |  |  |  |   __|__   |    //
//    |_____|____/|_____|_____|    //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract ODES is ERC1155Creator {
    constructor() ERC1155Creator("ODES", "ODES") {}
}
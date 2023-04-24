// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pla Seventeen
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                                 //
//           _         _ _____     //
//     _ __ | | __ _  / |___  |    //
//    | '_ \| |/ _` | | |  / /     //
//    | |_) | | (_| | | | / /      //
//    | .__/|_|\__,_| |_|/_/       //
//    |_|                          //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract PLA17 is ERC1155Creator {
    constructor() ERC1155Creator("Pla Seventeen", "PLA17") {}
}
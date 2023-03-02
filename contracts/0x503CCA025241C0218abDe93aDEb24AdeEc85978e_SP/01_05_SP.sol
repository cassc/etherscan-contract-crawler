// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SIAP editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//      _________.___   _____ __________                        //
//     /   _____/|   | /  _  \\______   \                       //
//     \_____  \ |   |/  /_\  \|     ___/                       //
//     /        \|   /    |    \    |                           //
//    /_______  /|___\____|__  /____|                           //
//            \/             \/                                 //
//    Winner of the International Portrait Photography Award    //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract SP is ERC1155Creator {
    constructor() ERC1155Creator("SIAP editions", "SP") {}
}
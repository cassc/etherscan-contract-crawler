// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bitcoin Pizza - Ordinal Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                88                                     //
//                ""                                     //
//                                                       //
//    8b,dPPYba,  88 888888888 888888888 ,adPPYYba,      //
//    88P'    "8a 88      a8P"      a8P" ""     `Y8      //
//    88       d8 88   ,d8P'     ,d8P'   ,adPPPPP88      //
//    88b,   ,a8" 88 ,d8"      ,d8"      88,    ,88      //
//    88`YbbdP"'  88 888888888 888888888 `"8bbdP"Y8      //
//    88                                                 //
//    88                                                 //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract BTCPIZZAORD is ERC1155Creator {
    constructor() ERC1155Creator("Bitcoin Pizza - Ordinal Edition", "BTCPIZZAORD") {}
}
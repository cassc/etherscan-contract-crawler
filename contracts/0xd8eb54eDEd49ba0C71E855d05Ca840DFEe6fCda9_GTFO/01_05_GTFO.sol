// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Floor It or GTFO
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//       ______  _________  ________    ___        //
//     .' ___  ||  _   _  ||_   __  | .'   `.      //
//    / .'   \_||_/ | | \_|  | |_ \_|/  .-.  \     //
//    | |   ____    | |      |  _|   | |   | |     //
//    \ `.___]  |  _| |_    _| |_    \  `-'  /     //
//     `._____.'  |_____|  |_____|    `.___.'      //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract GTFO is ERC1155Creator {
    constructor() ERC1155Creator("Floor It or GTFO", "GTFO") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by DaevidAdeola
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//        .___                      .__     .___     //
//      __| _/_____     ____ ___  __|__|  __| _/     //
//     / __ | \__  \  _/ __ \\  \/ /|  | / __ |      //
//    / /_/ |  / __ \_\  ___/ \   / |  |/ /_/ |      //
//    \____ | (____  / \___  > \_/  |__|\____ |      //
//         \/      \/      \/                \/      //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract EDA is ERC1155Creator {
    constructor() ERC1155Creator("Editions by DaevidAdeola", "EDA") {}
}
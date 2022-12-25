// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lysergic
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//      _                              _          //
//     | |                            (_)         //
//     | |    _   _ ___  ___ _ __ __ _ _  ___     //
//     | |   | | | / __|/ _ \ '__/ _` | |/ __|    //
//     | |___| |_| \__ \  __/ | | (_| | | (__     //
//     |______\__, |___/\___|_|  \__, |_|\___|    //
//             __/ |              __/ |           //
//            |___/              |___/            //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract LSD is ERC1155Creator {
    constructor() ERC1155Creator("Lysergic", "LSD") {}
}
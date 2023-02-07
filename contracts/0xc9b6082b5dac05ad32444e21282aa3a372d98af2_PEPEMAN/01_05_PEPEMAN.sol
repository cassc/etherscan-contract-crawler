// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPE-MAN Checks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//    ▄▀█ █▀█ ▀█▀   █ █▀   █░░ █▀█ █░█ █▀▀     //
//    █▀█ █▀▄ ░█░   █ ▄█   █▄▄ █▄█ ▀▄▀ ██▄     //
//                                             //
//    ▄▀█ █▄░█ █▀▄   █░░ █▀█ █░█ █▀▀   █ █▀    //
//    █▀█ █░▀█ █▄▀   █▄▄ █▄█ ▀▄▀ ██▄   █ ▄█    //
//                                             //
//    ▄▀█ █▀█ ▀█▀                              //
//    █▀█ █▀▄ ░█░                              //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract PEPEMAN is ERC1155Creator {
    constructor() ERC1155Creator("PEPE-MAN Checks", "PEPEMAN") {}
}
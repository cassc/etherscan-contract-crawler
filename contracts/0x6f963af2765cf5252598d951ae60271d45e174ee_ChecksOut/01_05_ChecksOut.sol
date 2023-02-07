// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: This Pepe Checks Out
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//                                                                     //
//     _____       _        _____        _____                         //
//    |     |___ _| |___   | __  |_ _   |_   _|___ ___ ___ ___ ___     //
//    | | | | .'| . | -_|  | __ -| | |    | | | .'|   | . |  _| .'|    //
//    |_|_|_|__,|___|___|  |_____|_  |    |_| |__,|_|_|_  |_| |__,|    //
//                               |___|                |___|            //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract ChecksOut is ERC1155Creator {
    constructor() ERC1155Creator("This Pepe Checks Out", "ChecksOut") {}
}
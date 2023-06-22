// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Timunpadi
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//                                             //
//     _____ _                         _ _     //
//    |_   _|_|_____ _ _ ___ ___ ___ _| |_|    //
//      | | | |     | | |   | . | .'| . | |    //
//      |_| |_|_|_|_|___|_|_|  _|__,|___|_|    //
//                          |_|                //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract TMNPD is ERC721Creator {
    constructor() ERC721Creator("Timunpadi", "TMNPD") {}
}
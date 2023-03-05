// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: zolfaqqari
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//                                             //
//                                             //
//             _ ___                     _     //
//     ___ ___| |  _|___ ___ ___ ___ ___|_|    //
//    |- _| . | |  _| .'| . | . | .'|  _| |    //
//    |___|___|_|_| |__,|_  |_  |__,|_| |_|    //
//                        |_| |_|              //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract zoq is ERC721Creator {
    constructor() ERC721Creator("zolfaqqari", "zoq") {}
}
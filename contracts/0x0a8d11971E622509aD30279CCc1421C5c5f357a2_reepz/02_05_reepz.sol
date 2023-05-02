// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HonoraReepz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//                                     //
//                                     //
//      _ __  ___   ___  _ __  ____    //
//     | '__|/ _ \ / _ \| '_ \|_  /    //
//     | |  |  __/|  __/| |_) |/ /     //
//     |_|   \___| \___|| .__//___|    //
//                      | |            //
//                      |_|            //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract reepz is ERC721Creator {
    constructor() ERC721Creator("HonoraReepz", "reepz") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: iRyanBell
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//     _ _____             _____     _ _     //
//    |_| __  |_ _ ___ ___| __  |___| | |    //
//    | |    -| | | .'|   | __ -| -_| | |    //
//    |_|__|__|_  |__,|_|_|_____|___|_|_|    //
//            |___|                          //
//                                           //
//                                           //
///////////////////////////////////////////////


contract iRB is ERC721Creator {
    constructor() ERC721Creator("iRyanBell", "iRB") {}
}
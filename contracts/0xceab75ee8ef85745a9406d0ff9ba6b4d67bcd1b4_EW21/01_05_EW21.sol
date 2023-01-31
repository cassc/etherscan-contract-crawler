// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: earlyWoRm
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                             _____                 //
//                 _     _ _ _|   | |_____           //
//     ___ ___ ___| |_ _| | | |_|___| __  |_____     //
//    | -_| .'|  _| | | | | | |     |    -|     |    //
//    |___|__,|_| |_|_  |_____|     |__|__|_|_|_|    //
//                  |___|                            //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract EW21 is ERC721Creator {
    constructor() ERC721Creator("earlyWoRm", "EW21") {}
}
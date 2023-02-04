// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The RTST
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//     _____ _____ _____ _____ _____ _____ _____     //
//    |_   _|  |  |   __| __  |_   _|   __|_   _|    //
//      | | |     |   __|    -| | | |__   | | |      //
//      |_| |__|__|_____|__|__| |_| |_____| |_|      //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract RTST is ERC721Creator {
    constructor() ERC721Creator("The RTST", "RTST") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lyndoco
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//     __    __ __ _____ ____  _____ _____ _____     //
//    |  |  |  |  |   | |    \|     |     |     |    //
//    |  |__|_   _| | | |  |  |  |  |   --|  |  |    //
//    |_____| |_| |_|___|____/|_____|_____|_____|    //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract LYN is ERC721Creator {
    constructor() ERC721Creator("Lyndoco", "LYN") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Green Man Social Club
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//     _______  __   __  _______  _______     //
//    |       ||  |_|  ||       ||       |    //
//    |    ___||       ||  _____||       |    //
//    |   | __ |       || |_____ |       |    //
//    |   ||  ||       ||_____  ||      _|    //
//    |   |_| || ||_|| | _____| ||     |_     //
//    |_______||_|   |_||_______||_______|    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract GMSC is ERC721Creator {
    constructor() ERC721Creator("Green Man Social Club", "GMSC") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Battle Of The Sneaks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    __________ ____________________________    //
//    \______   \\_____  \__    ___/   _____/    //
//     |    |  _/ /   |   \|    |  \_____  \     //
//     |    |   \/    |    \    |  /        \    //
//     |______  /\_______  /____| /_______  /    //
//            \/         \/               \/     //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract BOTS is ERC721Creator {
    constructor() ERC721Creator("Battle Of The Sneaks", "BOTS") {}
}
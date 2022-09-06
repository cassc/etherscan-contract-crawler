// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Randomly 1/1s
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//    █▀█ ▄▀█ █▄░█ █▀▄ █▀█ █▀▄▀█ █░░ █▄█   ▄█ ░░▄▀ ▄█    //
//    █▀▄ █▀█ █░▀█ █▄▀ █▄█ █░▀░█ █▄▄ ░█░   ░█ ▄▀░░ ░█    //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract RANDOMLY is ERC721Creator {
    constructor() ERC721Creator("Randomly 1/1s", "RANDOMLY") {}
}
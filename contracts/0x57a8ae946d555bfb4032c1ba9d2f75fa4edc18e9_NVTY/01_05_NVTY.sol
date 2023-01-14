// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NOVELTY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    ███    ██ ██    ██ ████████ ██    ██     //
//    ████   ██ ██    ██    ██     ██  ██      //
//    ██ ██  ██ ██    ██    ██      ████       //
//    ██  ██ ██  ██  ██     ██       ██        //
//    ██   ████   ████      ██       ██        //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract NVTY is ERC721Creator {
    constructor() ERC721Creator("NOVELTY", "NVTY") {}
}
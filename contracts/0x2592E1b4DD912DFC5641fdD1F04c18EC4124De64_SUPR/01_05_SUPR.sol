// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OBLYSK
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//     ██████  ██████  ██      ██    ██ ███████ ██   ██     //
//    ██    ██ ██   ██ ██       ██  ██  ██      ██  ██      //
//    ██    ██ ██████  ██        ████   ███████ █████       //
//    ██    ██ ██   ██ ██         ██         ██ ██  ██      //
//     ██████  ██████  ███████    ██    ███████ ██   ██     //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract SUPR is ERC721Creator {
    constructor() ERC721Creator("OBLYSK", "SUPR") {}
}
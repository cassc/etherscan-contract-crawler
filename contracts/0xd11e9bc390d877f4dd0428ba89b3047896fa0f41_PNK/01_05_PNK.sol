// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PUNK
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    ██████  ██    ██ ███    ██ ██   ██     //
//    ██   ██ ██    ██ ████   ██ ██  ██      //
//    ██████  ██    ██ ██ ██  ██ █████       //
//    ██      ██    ██ ██  ██ ██ ██  ██      //
//    ██       ██████  ██   ████ ██   ██     //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract PNK is ERC721Creator {
    constructor() ERC721Creator("PUNK", "PNK") {}
}
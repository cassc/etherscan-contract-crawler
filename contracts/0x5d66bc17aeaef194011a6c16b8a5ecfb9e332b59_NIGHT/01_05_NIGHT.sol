// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Northern Nights
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    ███    ██ ██  ██████  ██   ██ ████████     //
//    ████   ██ ██ ██       ██   ██    ██        //
//    ██ ██  ██ ██ ██   ███ ███████    ██        //
//    ██  ██ ██ ██ ██    ██ ██   ██    ██        //
//    ██   ████ ██  ██████  ██   ██    ██        //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract NIGHT is ERC721Creator {
    constructor() ERC721Creator("Northern Nights", "NIGHT") {}
}
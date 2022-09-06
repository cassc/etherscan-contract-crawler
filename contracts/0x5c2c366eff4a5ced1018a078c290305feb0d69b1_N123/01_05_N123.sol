// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Null
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//    ███    ██ ██    ██ ██      ██          //
//    ████   ██ ██    ██ ██      ██          //
//    ██ ██  ██ ██    ██ ██      ██          //
//    ██  ██ ██ ██    ██ ██      ██          //
//    ██   ████  ██████  ███████ ███████     //
//                                           //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract N123 is ERC721Creator {
    constructor() ERC721Creator("Null", "N123") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Twisted Reality
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//    ████████ ██     ██ ██ ███████ ████████ ███████ ██████      //
//       ██    ██     ██ ██ ██         ██    ██      ██   ██     //
//       ██    ██  █  ██ ██ ███████    ██    █████   ██   ██     //
//       ██    ██ ███ ██ ██      ██    ██    ██      ██   ██     //
//       ██     ███ ███  ██ ███████    ██    ███████ ██████      //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract TWISTED is ERC721Creator {
    constructor() ERC721Creator("Twisted Reality", "TWISTED") {}
}
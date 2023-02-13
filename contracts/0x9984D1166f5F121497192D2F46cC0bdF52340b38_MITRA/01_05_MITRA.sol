// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: a drop of earth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    ███    ███ ██ ████████ ██████   █████      //
//    ████  ████ ██    ██    ██   ██ ██   ██     //
//    ██ ████ ██ ██    ██    ██████  ███████     //
//    ██  ██  ██ ██    ██    ██   ██ ██   ██     //
//    ██      ██ ██    ██    ██   ██ ██   ██     //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract MITRA is ERC721Creator {
    constructor() ERC721Creator("a drop of earth", "MITRA") {}
}
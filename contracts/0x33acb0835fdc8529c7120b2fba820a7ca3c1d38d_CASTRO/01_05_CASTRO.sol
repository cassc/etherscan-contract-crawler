// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Castro 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//     ██████  █████  ███████ ████████ ██████   ██████      //
//    ██      ██   ██ ██         ██    ██   ██ ██    ██     //
//    ██      ███████ ███████    ██    ██████  ██    ██     //
//    ██      ██   ██      ██    ██    ██   ██ ██    ██     //
//     ██████ ██   ██ ███████    ██    ██   ██  ██████      //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract CASTRO is ERC721Creator {
    constructor() ERC721Creator("Castro 1/1s", "CASTRO") {}
}
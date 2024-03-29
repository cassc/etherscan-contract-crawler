// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Purz 1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//    ██████  ██    ██ ██████  ███████      ██  ██ ███████ ███████     //
//    ██   ██ ██    ██ ██   ██    ███      ███ ███ ██      ██          //
//    ██████  ██    ██ ██████    ███        ██  ██ ███████ ███████     //
//    ██      ██    ██ ██   ██  ███         ██  ██      ██      ██     //
//    ██       ██████  ██   ██ ███████      ██  ██ ███████ ███████     //
//                                                                     //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract PURZ2 is ERC1155Creator {
    constructor() ERC1155Creator("Purz 1155", "PURZ2") {}
}
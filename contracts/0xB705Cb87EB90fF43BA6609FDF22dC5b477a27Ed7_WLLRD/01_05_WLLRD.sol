// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WILLARD Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//                                                             //
//                                                             //
//    ██     ██ ██ ██      ██       █████  ██████  ██████      //
//    ██     ██ ██ ██      ██      ██   ██ ██   ██ ██   ██     //
//    ██  █  ██ ██ ██      ██      ███████ ██████  ██   ██     //
//    ██ ███ ██ ██ ██      ██      ██   ██ ██   ██ ██   ██     //
//     ███ ███  ██ ███████ ███████ ██   ██ ██   ██ ██████      //
//                                                             //
//                                                             //
//                                                             //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract WLLRD is ERC1155Creator {
    constructor() ERC1155Creator("WILLARD Editions", "WLLRD") {}
}
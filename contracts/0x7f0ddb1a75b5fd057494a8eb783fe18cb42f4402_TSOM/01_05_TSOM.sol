// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TSOM Pepe Le Hues Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    ████████ ███████  ██████  ███    ███     //
//       ██    ██      ██    ██ ████  ████     //
//       ██    ███████ ██    ██ ██ ████ ██     //
//       ██         ██ ██    ██ ██  ██  ██     //
//       ██    ███████  ██████  ██      ██     //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract TSOM is ERC1155Creator {
    constructor() ERC1155Creator("TSOM Pepe Le Hues Editions", "TSOM") {}
}
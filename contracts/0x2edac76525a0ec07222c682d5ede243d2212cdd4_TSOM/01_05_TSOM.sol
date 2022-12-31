// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TSOM ERC721 Contract
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

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


contract TSOM is ERC721Creator {
    constructor() ERC721Creator("TSOM ERC721 Contract", "TSOM") {}
}
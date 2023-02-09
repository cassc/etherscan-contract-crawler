// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - TTS Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    boobs    //
//             //
//             //
/////////////////


contract Boobs is ERC721Creator {
    constructor() ERC721Creator("Checks - TTS Edition", "Boobs") {}
}
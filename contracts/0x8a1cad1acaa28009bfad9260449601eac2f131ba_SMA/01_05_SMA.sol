// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: scat_music_art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    music    //
//             //
//             //
/////////////////


contract SMA is ERC721Creator {
    constructor() ERC721Creator("scat_music_art", "SMA") {}
}
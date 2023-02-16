// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Geijutsu no Tobira
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//     ██████  ██████     ██████  ██    ██     ██   ██     ██████      //
//    ██      ██          ██   ██  ██  ██      ██   ██    ██  ████     //
//    ██      ██          ██████    ████       ███████    ██ ██ ██     //
//    ██      ██          ██   ██    ██             ██    ████  ██     //
//     ██████  ██████     ██████     ██             ██ ██  ██████      //
//                                                                     //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract HIME is ERC721Creator {
    constructor() ERC721Creator("Geijutsu no Tobira", "HIME") {}
}
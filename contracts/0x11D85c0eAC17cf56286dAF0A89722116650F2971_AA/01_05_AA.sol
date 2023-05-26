// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ARCHIAMIGOS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    ▄▀█ █▀█ █▀▀ █ █ █ ▄▀█ █▀▄▀█ █ █▀▀ █▀█ █▀             //
//    █▀█ █▀▄ █▄▄ █▀█ █ █▀█ █ ▀ █ █ █▄█ █▄█ ▄█             //
//                                                         //
//    Good vibes for everyone! My tribute to Nakamigos.    //
//    I wish you have fun like me drawing ARCHIAMIGOS!     //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract AA is ERC721Creator {
    constructor() ERC721Creator("ARCHIAMIGOS", "AA") {}
}
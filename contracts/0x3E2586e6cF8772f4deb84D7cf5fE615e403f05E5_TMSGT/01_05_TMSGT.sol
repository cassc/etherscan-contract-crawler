// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tempus Fugit by Andrea Bonaceto
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    Tempus Fugit by Andrea Bonaceto    //
//                                       //
//                                       //
///////////////////////////////////////////


contract TMSGT is ERC721Creator {
    constructor() ERC721Creator("Tempus Fugit by Andrea Bonaceto", "TMSGT") {}
}
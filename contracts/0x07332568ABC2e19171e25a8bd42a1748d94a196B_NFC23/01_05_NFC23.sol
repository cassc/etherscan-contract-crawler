// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Awareness
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//    I am total solitude in the universe of my worlds...    //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract NFC23 is ERC721Creator {
    constructor() ERC721Creator("Awareness", "NFC23") {}
}
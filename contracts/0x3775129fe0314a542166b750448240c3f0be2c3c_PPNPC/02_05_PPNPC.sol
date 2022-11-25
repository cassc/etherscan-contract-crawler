// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: P3P3 & NPC
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    P3P3s are scarce     //
//    NPCs are abundant    //
//    _                    //
//    Greencross           //
//    (2022)               //
//                         //
//                         //
/////////////////////////////


contract PPNPC is ERC721Creator {
    constructor() ERC721Creator("P3P3 & NPC", "PPNPC") {}
}
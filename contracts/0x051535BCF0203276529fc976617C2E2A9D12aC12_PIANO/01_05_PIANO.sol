// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Not ACK Piano by 🌿420🌿
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    PIANO BY TIAGO    //
//                      //
//                      //
//////////////////////////


contract PIANO is ERC721Creator {
    constructor() ERC721Creator(unicode"Not ACK Piano by 🌿420🌿", "PIANO") {}
}
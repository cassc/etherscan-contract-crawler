// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ink and Rust
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    Ink  and  Rust    //
//          🌹          //
//                      //
//                      //
//////////////////////////


contract NKRST is ERC721Creator {
    constructor() ERC721Creator("Ink and Rust", "NKRST") {}
}
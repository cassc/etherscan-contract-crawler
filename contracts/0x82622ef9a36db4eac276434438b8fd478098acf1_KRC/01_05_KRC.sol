// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kitaro Remix Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    The Big Gooey     //
//                      //
//                      //
//                      //
//////////////////////////


contract KRC is ERC721Creator {
    constructor() ERC721Creator("Kitaro Remix Collection", "KRC") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: great silence (lyric book)
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    meta reespect.    //
//                      //
//                      //
//////////////////////////


contract lrk is ERC721Creator {
    constructor() ERC721Creator("great silence (lyric book)", "lrk") {}
}
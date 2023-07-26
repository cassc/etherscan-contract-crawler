// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fanart collection by Aotakana
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Japanese illustrator     //
//                             //
//                             //
/////////////////////////////////


contract FCA is ERC721Creator {
    constructor() ERC721Creator("Fanart collection by Aotakana", "FCA") {}
}
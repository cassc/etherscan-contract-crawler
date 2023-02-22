// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Human AI Nature by Korbinian Vogt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    Human AI Nature by Korbinian Vogt    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract HAIBKV is ERC721Creator {
    constructor() ERC721Creator("Human AI Nature by Korbinian Vogt", "HAIBKV") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Narrated Monologue by Korbinian Vogt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Works by Korbinian Vogt.    //
//                                //
//                                //
////////////////////////////////////


contract NMBKV is ERC721Creator {
    constructor() ERC721Creator("Narrated Monologue by Korbinian Vogt", "NMBKV") {}
}
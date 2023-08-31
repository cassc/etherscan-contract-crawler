// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Icon by Kobinian Vogt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Works by Korbinian Vogt.    //
//                                //
//                                //
////////////////////////////////////


contract IBKV is ERC721Creator {
    constructor() ERC721Creator("Icon by Kobinian Vogt", "IBKV") {}
}
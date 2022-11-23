// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LazyLab Dice 🎲
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    Âmi     //
//            //
//            //
////////////////


contract NFT is ERC721Creator {
    constructor() ERC721Creator(unicode"LazyLab Dice 🎲", "NFT") {}
}
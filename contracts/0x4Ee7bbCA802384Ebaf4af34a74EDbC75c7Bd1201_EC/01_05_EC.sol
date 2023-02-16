// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Evil Creatures
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Evil Creatures     //
//                       //
//                       //
///////////////////////////


contract EC is ERC721Creator {
    constructor() ERC721Creator("Evil Creatures", "EC") {}
}
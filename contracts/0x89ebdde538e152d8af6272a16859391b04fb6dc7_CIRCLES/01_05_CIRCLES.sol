// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Magical Circles
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Magical Circles    //
//                       //
//                       //
///////////////////////////


contract CIRCLES is ERC721Creator {
    constructor() ERC721Creator("Magical Circles", "CIRCLES") {}
}
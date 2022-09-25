// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lady Ape Club
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    Lady Ape Club     //
//                      //
//                      //
//////////////////////////


contract LAC is ERC721Creator {
    constructor() ERC721Creator("Lady Ape Club", "LAC") {}
}
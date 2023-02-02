// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A DAY IN LIFE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    A Day In Life    //
//                     //
//                     //
/////////////////////////


contract ADIL is ERC721Creator {
    constructor() ERC721Creator("A DAY IN LIFE", "ADIL") {}
}
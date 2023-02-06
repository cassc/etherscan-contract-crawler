// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HuDun
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    My name is HuDun.     //
//                          //
//                          //
//////////////////////////////


contract HD is ERC721Creator {
    constructor() ERC721Creator("HuDun", "HD") {}
}
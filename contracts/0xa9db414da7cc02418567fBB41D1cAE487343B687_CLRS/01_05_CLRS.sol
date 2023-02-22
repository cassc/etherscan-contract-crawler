// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Colors
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Colors by WMA    //
//                     //
//                     //
/////////////////////////


contract CLRS is ERC721Creator {
    constructor() ERC721Creator("Colors", "CLRS") {}
}
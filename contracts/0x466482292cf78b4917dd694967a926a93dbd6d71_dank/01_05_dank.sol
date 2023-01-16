// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Untitled
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Untitled.    //
//                 //
//                 //
/////////////////////


contract dank is ERC721Creator {
    constructor() ERC721Creator("Untitled", "dank") {}
}
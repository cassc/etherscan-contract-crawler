// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - Mfer Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    gm mfers    //
//                //
//                //
////////////////////


contract MFER is ERC721Creator {
    constructor() ERC721Creator("Checks - Mfer Edition", "MFER") {}
}
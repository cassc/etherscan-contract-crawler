// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JUP Ape Isoptera Fishing Sticks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    =========D    //
//                  //
//                  //
//////////////////////


contract JUPFS is ERC721Creator {
    constructor() ERC721Creator("JUP Ape Isoptera Fishing Sticks", "JUPFS") {}
}
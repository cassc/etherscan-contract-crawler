// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: You're well, how am I?
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    Ervis did this    //
//                      //
//                      //
//////////////////////////


contract ETG is ERC721Creator {
    constructor() ERC721Creator("You're well, how am I?", "ETG") {}
}
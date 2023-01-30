// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: R3ND3R
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    ¯\_(ツ)_/¯    //
//                 //
//                 //
/////////////////////


contract RND3R is ERC721Creator {
    constructor() ERC721Creator("R3ND3R", "RND3R") {}
}
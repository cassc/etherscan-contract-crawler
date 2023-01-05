// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hareiro_Open Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    ☆☆☆_φ(･_･    //
//                 //
//                 //
/////////////////////


contract HAREMA is ERC721Creator {
    constructor() ERC721Creator("Hareiro_Open Edition", "HAREMA") {}
}
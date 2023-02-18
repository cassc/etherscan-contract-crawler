// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Figurehead
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Figurehead     //
//                   //
//                   //
///////////////////////


contract FH1 is ERC721Creator {
    constructor() ERC721Creator("Figurehead", "FH1") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Enneoteuthis
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    0xFinella    //
//                 //
//                 //
/////////////////////


contract ETT is ERC721Creator {
    constructor() ERC721Creator("Enneoteuthis", "ETT") {}
}
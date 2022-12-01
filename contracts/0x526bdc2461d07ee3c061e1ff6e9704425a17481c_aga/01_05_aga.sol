// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ali Guzel Abstracts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    aliguzelart    //
//                   //
//                   //
///////////////////////


contract aga is ERC721Creator {
    constructor() ERC721Creator("Ali Guzel Abstracts", "aga") {}
}
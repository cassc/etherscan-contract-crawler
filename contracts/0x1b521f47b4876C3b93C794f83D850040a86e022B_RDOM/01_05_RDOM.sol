// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Random #1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    dmp RDM#1    //
//                 //
//                 //
/////////////////////


contract RDOM is ERC721Creator {
    constructor() ERC721Creator("Random #1", "RDOM") {}
}
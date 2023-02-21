// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mantest1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    @@@@@@@@@    //
//                 //
//                 //
/////////////////////


contract MT1 is ERC721Creator {
    constructor() ERC721Creator("Mantest1", "MT1") {}
}
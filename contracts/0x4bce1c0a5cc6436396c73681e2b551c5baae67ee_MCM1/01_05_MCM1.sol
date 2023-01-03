// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: METACROMAGNON 1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    MCM01.TAC    //
//                 //
//                 //
/////////////////////


contract MCM1 is ERC721Creator {
    constructor() ERC721Creator("METACROMAGNON 1/1", "MCM1") {}
}
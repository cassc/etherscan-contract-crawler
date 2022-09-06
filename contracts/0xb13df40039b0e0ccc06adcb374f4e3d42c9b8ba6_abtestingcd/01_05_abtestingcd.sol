// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Testing
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    hello world    //
//                   //
//                   //
///////////////////////


contract abtestingcd is ERC721Creator {
    constructor() ERC721Creator("Testing", "abtestingcd") {}
}
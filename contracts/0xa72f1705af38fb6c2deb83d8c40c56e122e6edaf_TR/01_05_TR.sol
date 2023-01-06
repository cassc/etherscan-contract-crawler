// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TestRun
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    --TR--    //
//              //
//              //
//////////////////


contract TR is ERC721Creator {
    constructor() ERC721Creator("TestRun", "TR") {}
}
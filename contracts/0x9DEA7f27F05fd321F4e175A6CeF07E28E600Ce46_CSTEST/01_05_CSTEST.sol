// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    CSCSCSCSCS    //
//                  //
//                  //
//////////////////////


contract CSTEST is ERC721Creator {
    constructor() ERC721Creator("Test", "CSTEST") {}
}
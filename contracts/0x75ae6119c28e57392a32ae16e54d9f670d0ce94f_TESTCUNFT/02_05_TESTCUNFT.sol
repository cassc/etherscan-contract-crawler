// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Catalyst Contract
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    TESTCUTNFT    //
//                  //
//                  //
//////////////////////


contract TESTCUNFT is ERC721Creator {
    constructor() ERC721Creator("Test Catalyst Contract", "TESTCUNFT") {}
}
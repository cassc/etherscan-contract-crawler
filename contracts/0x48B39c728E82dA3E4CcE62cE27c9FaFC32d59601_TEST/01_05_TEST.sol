// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Dummy X
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    asci    //
//            //
//            //
////////////////


contract TEST is ERC721Creator {
    constructor() ERC721Creator("Test Dummy X", "TEST") {}
}
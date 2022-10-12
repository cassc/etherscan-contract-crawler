// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test1234124
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    test    //
//            //
//            //
////////////////


contract Test is ERC721Creator {
    constructor() ERC721Creator("Test1234124", "Test") {}
}
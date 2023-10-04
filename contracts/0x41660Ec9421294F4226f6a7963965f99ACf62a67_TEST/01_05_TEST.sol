// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    test    //
//            //
//            //
////////////////


contract TEST is ERC721Creator {
    constructor() ERC721Creator("test", "TEST") {}
}
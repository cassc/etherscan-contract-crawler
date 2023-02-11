// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mozzu test
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    test    //
//            //
//            //
////////////////


contract test is ERC721Creator {
    constructor() ERC721Creator("mozzu test", "test") {}
}
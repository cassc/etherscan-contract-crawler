// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: testy1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    test    //
//            //
//            //
////////////////


contract tst1 is ERC721Creator {
    constructor() ERC721Creator("testy1", "tst1") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: testing nothingness
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    test    //
//            //
//            //
////////////////


contract tst is ERC721Creator {
    constructor() ERC721Creator("testing nothingness", "tst") {}
}
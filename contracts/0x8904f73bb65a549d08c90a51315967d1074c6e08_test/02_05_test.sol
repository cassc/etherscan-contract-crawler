// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test123
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    test    //
//            //
//            //
////////////////


contract test is ERC1155Creator {
    constructor() ERC1155Creator("test123", "test") {}
}
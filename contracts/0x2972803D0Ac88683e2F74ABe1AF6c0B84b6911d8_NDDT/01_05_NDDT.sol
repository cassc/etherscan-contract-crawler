// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    test    //
//            //
//            //
////////////////


contract NDDT is ERC1155Creator {
    constructor() ERC1155Creator("Test", "NDDT") {}
}
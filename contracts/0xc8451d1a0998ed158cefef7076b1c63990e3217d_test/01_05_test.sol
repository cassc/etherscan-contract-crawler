// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: testing multi
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
    constructor() ERC1155Creator("testing multi", "test") {}
}
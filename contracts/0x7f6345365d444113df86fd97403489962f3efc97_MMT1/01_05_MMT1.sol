// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MM Test 1
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    This is a test contract    //
//                               //
//                               //
///////////////////////////////////


contract MMT1 is ERC1155Creator {
    constructor() ERC1155Creator("MM Test 1", "MMT1") {}
}
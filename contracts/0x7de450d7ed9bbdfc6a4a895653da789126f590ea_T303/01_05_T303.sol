// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test 303
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    xxxxx-----xxxxx    //
//                       //
//                       //
///////////////////////////


contract T303 is ERC721Creator {
    constructor() ERC721Creator("Test 303", "T303") {}
}
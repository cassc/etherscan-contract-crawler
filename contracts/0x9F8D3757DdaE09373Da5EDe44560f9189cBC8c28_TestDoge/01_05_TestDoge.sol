// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TestDoge
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    TestDoge    //
//                //
//                //
////////////////////


contract TestDoge is ERC1155Creator {
    constructor() ERC1155Creator("TestDoge", "TestDoge") {}
}
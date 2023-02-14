// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Extension v2
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    hi    //
//          //
//          //
//////////////


contract testextv2 is ERC1155Creator {
    constructor() ERC1155Creator("Test Extension v2", "testextv2") {}
}
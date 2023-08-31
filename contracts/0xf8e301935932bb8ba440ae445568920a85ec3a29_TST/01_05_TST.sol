// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test111
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    dd    //
//          //
//          //
//////////////


contract TST is ERC1155Creator {
    constructor() ERC1155Creator("Test111", "TST") {}
}
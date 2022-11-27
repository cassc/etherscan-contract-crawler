// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    TESTING...    //
//                  //
//                  //
//////////////////////


contract TST is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
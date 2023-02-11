// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Cha
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    TEST CHA    //
//                //
//                //
////////////////////


contract Cha is ERC1155Creator {
    constructor() ERC1155Creator("Test Cha", "Cha") {}
}
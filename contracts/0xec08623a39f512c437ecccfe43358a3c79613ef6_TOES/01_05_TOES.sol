// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Contract
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    Test Contract    //
//                     //
//                     //
/////////////////////////


contract TOES is ERC1155Creator {
    constructor() ERC1155Creator("Test Contract", "TOES") {}
}
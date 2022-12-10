// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Contract
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    One two three    //
//                     //
//                     //
/////////////////////////


contract testotr is ERC1155Creator {
    constructor() ERC1155Creator("Test Contract", "testotr") {}
}
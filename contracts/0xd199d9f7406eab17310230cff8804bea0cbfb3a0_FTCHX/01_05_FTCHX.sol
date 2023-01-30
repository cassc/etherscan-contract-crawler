// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Feet Checks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    feet > heaven    //
//                     //
//                     //
/////////////////////////


contract FTCHX is ERC1155Creator {
    constructor() ERC1155Creator("Feet Checks", "FTCHX") {}
}
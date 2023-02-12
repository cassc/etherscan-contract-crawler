// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks Burning
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    Checks Burning    //
//                      //
//                      //
//////////////////////////


contract CB is ERC1155Creator {
    constructor() ERC1155Creator("Checks Burning", "CB") {}
}
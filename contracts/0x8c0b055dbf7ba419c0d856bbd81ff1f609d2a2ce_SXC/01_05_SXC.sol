// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shax Contract
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    Deus solus Rex    //
//                      //
//                      //
//////////////////////////


contract SXC is ERC1155Creator {
    constructor() ERC1155Creator("Shax Contract", "SXC") {}
}
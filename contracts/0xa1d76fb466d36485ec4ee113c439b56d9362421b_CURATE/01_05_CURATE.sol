// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Curated Collection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    curated collection by Tristan Rettich    //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract CURATE is ERC1155Creator {
    constructor() ERC1155Creator("Curated Collection", "CURATE") {}
}
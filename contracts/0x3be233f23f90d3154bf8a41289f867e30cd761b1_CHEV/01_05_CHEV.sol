// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - Egido Val Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    CHECKS BY EGIDO VAL.     //
//                             //
//                             //
/////////////////////////////////


contract CHEV is ERC1155Creator {
    constructor() ERC1155Creator("Checks - Egido Val Edition", "CHEV") {}
}
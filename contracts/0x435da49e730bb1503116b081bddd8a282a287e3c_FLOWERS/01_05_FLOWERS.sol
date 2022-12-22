// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FLOWERS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    FLOWERS EXPERIENCE     //
//                           //
//                           //
///////////////////////////////


contract FLOWERS is ERC1155Creator {
    constructor() ERC1155Creator("FLOWERS", "FLOWERS") {}
}
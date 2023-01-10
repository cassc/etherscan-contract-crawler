// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: a single seed
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    a single seed    //
//                     //
//                     //
/////////////////////////


contract seed is ERC1155Creator {
    constructor() ERC1155Creator("a single seed", "seed") {}
}
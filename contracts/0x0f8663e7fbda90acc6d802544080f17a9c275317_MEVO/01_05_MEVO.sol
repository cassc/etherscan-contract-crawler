// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: memevortex
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    💭    //
//          //
//          //
//////////////


contract MEVO is ERC1155Creator {
    constructor() ERC1155Creator("memevortex", "MEVO") {}
}
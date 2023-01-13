// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DECOMPOSIMPSONZ
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    BLEO    //
//            //
//            //
////////////////


contract DCSP is ERC1155Creator {
    constructor() ERC1155Creator("DECOMPOSIMPSONZ", "DCSP") {}
}
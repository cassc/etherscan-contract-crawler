// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MAGO EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    MAGO TIMES    //
//                  //
//                  //
//////////////////////


contract TIMES is ERC1155Creator {
    constructor() ERC1155Creator("MAGO EDITIONS", "TIMES") {}
}
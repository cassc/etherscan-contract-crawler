// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life Work Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    LIFE    //
//            //
//            //
////////////////


contract LIFE is ERC1155Creator {
    constructor() ERC1155Creator("Life Work Editions", "LIFE") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: First Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    GGWP    //
//            //
//            //
////////////////


contract LP is ERC1155Creator {
    constructor() ERC1155Creator("First Edition", "LP") {}
}
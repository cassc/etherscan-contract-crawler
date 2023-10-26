// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Super Metal Mons base set1 kit1 COA
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    mons    //
//            //
//            //
////////////////


contract smmbs1k1 is ERC1155Creator {
    constructor() ERC1155Creator("Super Metal Mons base set1 kit1 COA", "smmbs1k1") {}
}
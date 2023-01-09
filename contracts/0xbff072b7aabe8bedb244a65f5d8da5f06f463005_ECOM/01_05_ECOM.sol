// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Emotional Complexity
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    ECOM    //
//            //
//            //
////////////////


contract ECOM is ERC1155Creator {
    constructor() ERC1155Creator("Emotional Complexity", "ECOM") {}
}
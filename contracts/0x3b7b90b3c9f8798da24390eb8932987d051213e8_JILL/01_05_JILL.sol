// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JILL
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    JILL    //
//            //
//            //
////////////////


contract JILL is ERC1155Creator {
    constructor() ERC1155Creator("JILL", "JILL") {}
}
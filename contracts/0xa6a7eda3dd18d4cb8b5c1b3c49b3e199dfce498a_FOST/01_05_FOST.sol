// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fodcom Store
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    FOST    //
//            //
//            //
////////////////


contract FOST is ERC1155Creator {
    constructor() ERC1155Creator("Fodcom Store", "FOST") {}
}
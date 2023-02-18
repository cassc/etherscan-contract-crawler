// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: elBee Curated
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//    A curated collection of artwork & photography presented by ELBizzle    //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract ELBC is ERC1155Creator {
    constructor() ERC1155Creator("elBee Curated", "ELBC") {}
}
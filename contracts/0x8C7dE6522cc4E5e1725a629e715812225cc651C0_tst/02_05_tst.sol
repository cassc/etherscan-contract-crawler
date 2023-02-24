// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: testcontractbis
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    ASIC    //
//            //
//            //
////////////////


contract tst is ERC1155Creator {
    constructor() ERC1155Creator("testcontractbis", "tst") {}
}
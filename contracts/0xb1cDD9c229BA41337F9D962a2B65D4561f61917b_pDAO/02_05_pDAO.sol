// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pDAO PASS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    pDAO    //
//            //
//            //
////////////////


contract pDAO is ERC1155Creator {
    constructor() ERC1155Creator("pDAO PASS", "pDAO") {}
}
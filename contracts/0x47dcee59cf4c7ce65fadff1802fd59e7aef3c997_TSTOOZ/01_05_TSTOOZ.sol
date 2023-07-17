// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Testing
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    Testing     //
//                //
//                //
////////////////////


contract TSTOOZ is ERC1155Creator {
    constructor() ERC1155Creator("Testing", "TSTOOZ") {}
}
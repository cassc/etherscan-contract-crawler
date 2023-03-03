// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LINE IN BLUE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    L  I  B     //
//                //
//                //
////////////////////


contract LIB is ERC1155Creator {
    constructor() ERC1155Creator("LINE IN BLUE", "LIB") {}
}
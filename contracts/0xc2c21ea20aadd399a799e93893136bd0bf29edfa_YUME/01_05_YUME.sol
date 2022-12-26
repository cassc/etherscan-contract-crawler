// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yume
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    o((*^▽^*))o    //
//                   //
//                   //
///////////////////////


contract YUME is ERC1155Creator {
    constructor() ERC1155Creator("Yume", "YUME") {}
}
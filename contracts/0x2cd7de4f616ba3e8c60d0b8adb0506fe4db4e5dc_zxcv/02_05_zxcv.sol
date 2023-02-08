// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: zxcv
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    zxcv    //
//            //
//            //
////////////////


contract zxcv is ERC1155Creator {
    constructor() ERC1155Creator("zxcv", "zxcv") {}
}
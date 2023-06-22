// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: exsurdism
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    shit    //
//            //
//            //
////////////////


contract XSURD is ERC1155Creator {
    constructor() ERC1155Creator("exsurdism", "XSURD") {}
}
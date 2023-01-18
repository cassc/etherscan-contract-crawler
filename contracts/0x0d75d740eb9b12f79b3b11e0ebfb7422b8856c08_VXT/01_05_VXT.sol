// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Invxtation
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    MXKE    //
//            //
//            //
////////////////


contract VXT is ERC1155Creator {
    constructor() ERC1155Creator("The Invxtation", "VXT") {}
}
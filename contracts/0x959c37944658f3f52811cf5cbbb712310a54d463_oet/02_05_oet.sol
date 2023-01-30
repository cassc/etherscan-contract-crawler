// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: open edition test
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    hehe    //
//            //
//            //
////////////////


contract oet is ERC1155Creator {
    constructor() ERC1155Creator("open edition test", "oet") {}
}
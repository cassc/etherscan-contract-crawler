// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BoredApeYc
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    BAYC    //
//            //
//            //
////////////////


contract BAYC is ERC1155Creator {
    constructor() ERC1155Creator("BoredApeYc", "BAYC") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: gm, hangover?
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    gmho    //
//            //
//            //
////////////////


contract gmho is ERC1155Creator {
    constructor() ERC1155Creator("gm, hangover?", "gmho") {}
}
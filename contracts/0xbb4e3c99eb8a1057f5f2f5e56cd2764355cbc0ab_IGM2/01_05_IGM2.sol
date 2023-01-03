// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: it_gleam B
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    it_gleam    //
//                //
//                //
////////////////////


contract IGM2 is ERC1155Creator {
    constructor() ERC1155Creator("it_gleam B", "IGM2") {}
}
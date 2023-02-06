// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: second
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    dddd    //
//            //
//            //
////////////////


contract seco is ERC1155Creator {
    constructor() ERC1155Creator("second", "seco") {}
}
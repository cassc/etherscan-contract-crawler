// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Paji's Secret Information
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    paji    //
//            //
//            //
////////////////


contract PSIN is ERC1155Creator {
    constructor() ERC1155Creator("Paji's Secret Information", "PSIN") {}
}
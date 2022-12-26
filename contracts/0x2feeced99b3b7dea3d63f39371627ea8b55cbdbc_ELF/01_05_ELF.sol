// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions x Lisa Fogarty
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    nftlisa    //
//               //
//               //
///////////////////


contract ELF is ERC1155Creator {
    constructor() ERC1155Creator("Editions x Lisa Fogarty", "ELF") {}
}
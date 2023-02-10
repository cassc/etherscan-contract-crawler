// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ordinal Pepe Checks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    BITCOIN    //
//               //
//               //
///////////////////


contract OPC is ERC721Creator {
    constructor() ERC721Creator("Ordinal Pepe Checks", "OPC") {}
}
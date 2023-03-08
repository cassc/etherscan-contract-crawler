// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CrypticProductions OG
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    5r1pt1c    //
//               //
//               //
///////////////////


contract CPOG is ERC1155Creator {
    constructor() ERC1155Creator("CrypticProductions OG", "CPOG") {}
}
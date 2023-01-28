// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Satoshi's Sodas
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    Satoshi    //
//               //
//               //
///////////////////


contract SATSODA is ERC1155Creator {
    constructor() ERC1155Creator("Satoshi's Sodas", "SATSODA") {}
}
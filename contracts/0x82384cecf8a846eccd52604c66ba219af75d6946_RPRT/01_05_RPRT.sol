// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rare Pepe's Road Trip
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    rpskd23    //
//               //
//               //
///////////////////


contract RPRT is ERC1155Creator {
    constructor() ERC1155Creator("Rare Pepe's Road Trip", "RPRT") {}
}
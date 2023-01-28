// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BurnTheFlowers
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    Flowers    //
//               //
//               //
///////////////////


contract Burn is ERC1155Creator {
    constructor() ERC1155Creator("BurnTheFlowers", "Burn") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jokers
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    JOKES    //
//             //
//             //
/////////////////


contract JOKES is ERC1155Creator {
    constructor() ERC1155Creator("Jokers", "JOKES") {}
}
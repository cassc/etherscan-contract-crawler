// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bob's Bargain Basement
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    Bargains Galore    //
//                       //
//                       //
///////////////////////////


contract BBB is ERC1155Creator {
    constructor() ERC1155Creator("Bob's Bargain Basement", "BBB") {}
}
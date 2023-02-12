// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ordinal BTC Eggs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Ordinal BTC Eggs     //
//    Ordinal BTC Eggs     //
//    Ordinal BTC Eggs     //
//    Ordinal BTC Eggs     //
//                         //
//                         //
/////////////////////////////


contract OBEGGS is ERC1155Creator {
    constructor() ERC1155Creator("Ordinal BTC Eggs", "OBEGGS") {}
}
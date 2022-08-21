// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OrdinarySeries
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    ORDINARY SERIES    //
//                       //
//                       //
///////////////////////////


contract OSRS is ERC721Creator {
    constructor() ERC721Creator("OrdinarySeries", "OSRS") {}
}
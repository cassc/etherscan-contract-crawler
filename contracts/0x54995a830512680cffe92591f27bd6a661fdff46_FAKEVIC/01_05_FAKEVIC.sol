// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FAKEVICTORY
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    FAHJ    //
//            //
//            //
////////////////


contract FAKEVIC is ERC1155Creator {
    constructor() ERC1155Creator("FAKEVICTORY", "FAKEVIC") {}
}
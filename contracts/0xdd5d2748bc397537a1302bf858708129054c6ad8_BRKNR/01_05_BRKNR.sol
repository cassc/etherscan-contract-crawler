// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: bruckner
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//    BRUCKNER the bronx    //
//                          //
//                          //
//////////////////////////////


contract BRKNR is ERC1155Creator {
    constructor() ERC1155Creator("bruckner", "BRKNR") {}
}
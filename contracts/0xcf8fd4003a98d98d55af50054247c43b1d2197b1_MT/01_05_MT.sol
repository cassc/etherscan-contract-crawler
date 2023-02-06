// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Earth Mother
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    @malcolmtowers :)    //
//                         //
//                         //
/////////////////////////////


contract MT is ERC1155Creator {
    constructor() ERC1155Creator("Earth Mother", "MT") {}
}
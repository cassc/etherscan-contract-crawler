// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Studio XX
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    XX    //
//          //
//          //
//////////////


contract XX is ERC1155Creator {
    constructor() ERC1155Creator("Studio XX", "XX") {}
}
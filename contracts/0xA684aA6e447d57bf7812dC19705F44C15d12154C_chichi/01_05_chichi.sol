// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chichi's Art
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    <3    //
//          //
//          //
//////////////


contract chichi is ERC1155Creator {
    constructor() ERC1155Creator("Chichi's Art", "chichi") {}
}
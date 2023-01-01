// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    gm    //
//          //
//          //
//////////////


contract EDITS is ERC1155Creator {
    constructor() ERC1155Creator("Editions", "EDITS") {}
}
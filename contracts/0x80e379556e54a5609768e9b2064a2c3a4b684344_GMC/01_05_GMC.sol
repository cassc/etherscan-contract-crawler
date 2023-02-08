// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM CHECKS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    gm    //
//          //
//          //
//////////////


contract GMC is ERC1155Creator {
    constructor() ERC1155Creator("GM CHECKS", "GMC") {}
}
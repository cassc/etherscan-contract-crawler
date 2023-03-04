// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - ENS Avatar Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    ☑️    //
//          //
//          //
//////////////


contract CHECK is ERC1155Creator {
    constructor() ERC1155Creator("Checks - ENS Avatar Edition", "CHECK") {}
}
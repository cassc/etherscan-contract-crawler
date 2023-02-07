// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - Croakz Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    CROAKZ    //
//              //
//              //
//////////////////


contract CROAKZ is ERC1155Creator {
    constructor() ERC1155Creator("Checks - Croakz Edition", "CROAKZ") {}
}
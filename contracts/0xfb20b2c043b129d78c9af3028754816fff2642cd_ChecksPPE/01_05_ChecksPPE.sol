// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks -  Pepe Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Checks - Pepe Edition    //
//                             //
//                             //
/////////////////////////////////


contract ChecksPPE is ERC1155Creator {
    constructor() ERC1155Creator("Checks -  Pepe Edition", "ChecksPPE") {}
}
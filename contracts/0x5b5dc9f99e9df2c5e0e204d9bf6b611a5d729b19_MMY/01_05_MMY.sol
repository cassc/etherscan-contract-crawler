// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mummy Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    000editions000     //
//    00000000000000     //
//    000000m0000000     //
//    000000u0000000     //
//    000000m0000000     //
//    000000m0000000     //
//    000000y0000000     //
//    00000000000000     //
//                       //
//                       //
///////////////////////////


contract MMY is ERC1155Creator {
    constructor() ERC1155Creator("Mummy Editions", "MMY") {}
}
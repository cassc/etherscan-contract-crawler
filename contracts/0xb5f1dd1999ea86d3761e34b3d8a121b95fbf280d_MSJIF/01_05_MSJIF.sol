// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MS_JIF
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    MS_JIF EDITIONS    //
//                       //
//                       //
///////////////////////////


contract MSJIF is ERC1155Creator {
    constructor() ERC1155Creator("MS_JIF", "MSJIF") {}
}
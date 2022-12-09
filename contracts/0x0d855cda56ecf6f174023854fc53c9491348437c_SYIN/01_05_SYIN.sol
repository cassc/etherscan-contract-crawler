// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Symphony Inside
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    Symphony Inside    //
//                       //
//                       //
///////////////////////////


contract SYIN is ERC1155Creator {
    constructor() ERC1155Creator("Symphony Inside", "SYIN") {}
}
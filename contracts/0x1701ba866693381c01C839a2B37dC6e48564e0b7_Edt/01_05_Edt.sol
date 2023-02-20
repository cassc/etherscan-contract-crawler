// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions FranklinkART
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    Minimalism art    //
//                      //
//                      //
//////////////////////////


contract Edt is ERC1155Creator {
    constructor() ERC1155Creator("Editions FranklinkART", "Edt") {}
}
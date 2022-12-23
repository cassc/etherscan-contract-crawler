// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shark Tank
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    s0meone_u_know    //
//                      //
//                      //
//////////////////////////


contract SharkT is ERC1155Creator {
    constructor() ERC1155Creator("Shark Tank", "SharkT") {}
}
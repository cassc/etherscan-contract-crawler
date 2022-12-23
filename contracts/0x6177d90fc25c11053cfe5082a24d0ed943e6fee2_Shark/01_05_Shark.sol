// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shark Tank
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    s0meone_u_know    //
//                      //
//                      //
//////////////////////////


contract Shark is ERC721Creator {
    constructor() ERC721Creator("Shark Tank", "Shark") {}
}
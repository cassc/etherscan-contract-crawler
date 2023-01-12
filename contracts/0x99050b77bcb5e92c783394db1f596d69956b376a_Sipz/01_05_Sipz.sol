// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SimpsonZ
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    SimpsonZ lines    //
//                      //
//                      //
//////////////////////////


contract Sipz is ERC721Creator {
    constructor() ERC721Creator("SimpsonZ", "Sipz") {}
}
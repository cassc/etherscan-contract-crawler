// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HangMan
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    Can you guess?    //
//                      //
//                      //
//////////////////////////


contract HMN is ERC1155Creator {
    constructor() ERC1155Creator("HangMan", "HMN") {}
}
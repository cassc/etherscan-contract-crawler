// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kung Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    .-.,-..-.,-..---..---.    //
//    | . < | . < | |'_| |-     //
//    `-'`-'`-'`-'`-'-/`---'    //
//                              //
//                              //
//                              //
//////////////////////////////////


contract KKGE is ERC1155Creator {
    constructor() ERC1155Creator("Kung Edition", "KKGE") {}
}
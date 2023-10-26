// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Existence of a Samurai
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    “I dreamt of worldly success once.”      //
//                                             //
//    – Miyamoto Musashi                       //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract EOS is ERC1155Creator {
    constructor() ERC1155Creator("The Existence of a Samurai", "EOS") {}
}
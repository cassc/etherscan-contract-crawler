// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ANIMAL 1/1s
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//                                                                   //
//        \     \ | _ _|   \  |    \    |      _ |    / _ |          //
//       _ \   .  |   |   |\/ |   _ \   |        |   /    | (_-<     //
//     _/  _\ _|\_| ___| _|  _| _/  _\ ____|    _| _/    _| ___/     //
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract AN121 is ERC721Creator {
    constructor() ERC721Creator("ANIMAL 1/1s", "AN121") {}
}
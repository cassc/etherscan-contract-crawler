// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Magically Go Poof!
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//    .  .             ..     .__      .__       ._ |       //
//    |\/| _. _ * _. _.||  .  [ __ _   [__) _  _ |, |       //
//    |  |(_](_]|(_.(_]||\_|  [_./(_)  |   (_)(_)|  *       //
//           ._|         ._|                                //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract MGP is ERC1155Creator {
    constructor() ERC1155Creator("Magically Go Poof!", "MGP") {}
}
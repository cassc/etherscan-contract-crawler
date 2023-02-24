// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Magically Go Poof!
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

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


contract MGP is ERC721Creator {
    constructor() ERC721Creator("Magically Go Poof!", "MGP") {}
}
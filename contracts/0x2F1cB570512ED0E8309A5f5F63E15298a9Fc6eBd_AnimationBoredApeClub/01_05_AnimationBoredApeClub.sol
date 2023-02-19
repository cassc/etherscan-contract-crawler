// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AnimationBoredApeClub
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    Animation  Bored Ape Club    //
//                                 //
//                                 //
/////////////////////////////////////


contract AnimationBoredApeClub is ERC1155Creator {
    constructor() ERC1155Creator("AnimationBoredApeClub", "AnimationBoredApeClub") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Animation  Bored Ape Club
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//    Holding the Animation  Bored  Ape can get the metaverse land airdrop.    //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract ABAC is ERC1155Creator {
    constructor() ERC1155Creator("Animation  Bored Ape Club", "ABAC") {}
}